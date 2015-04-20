
"""PgQ consumer framework for Python.

"""

from pgq.baseconsumer import BaseConsumer, BaseBatchWalker
from pgq.event import Event

__all__ = ['Consumer']


# Event status codes
EV_UNTAGGED = -1
EV_RETRY = 0
EV_DONE = 1


class RetriableEvent(Event):
    """Event which can be retried

    Consumer is supposed to tag them after processing.
    """
    __slots__ = ('_status', )

    def __init__(self, queue_name, row):
        super(RetriableEvent, self).__init__(queue_name, row)
        self._status = EV_DONE

    def tag_done(self):
        self._status = EV_DONE

    def get_status(self):
        return self._status

    def tag_retry(self, retry_time = 60):
        self._status = EV_RETRY
        self.retry_time = retry_time


class RetriableWalkerEvent(RetriableEvent):
    """Redirects status flags to RetriableBatchWalker.

    That way event data can be gc'd immediately and
    tag_done() events don't need to be remembered.
    """
    __slots__ = ('_walker', )

    def __init__(self, walker, queue_name, row):
        super(RetriableWalkerEvent, self).__init__(queue_name, row)
        self._walker = walker

    def tag_done(self):
        self._walker.tag_event_done(self)

    def get_status(self):
        self._walker.get_status(self)

    def tag_retry(self, retry_time = 60):
        self._walker.tag_event_retry(self, retry_time)


class RetriableBatchWalker(BaseBatchWalker):
    """BatchWalker that returns RetriableEvents
    """

    def __init__(self, curs, batch_id, queue_name, fetch_size = 300, consumer_filter = None):
        super(RetriableBatchWalker, self).__init__(curs, batch_id, queue_name, fetch_size, consumer_filter)
        self.status_map = {}

    def _make_event(self, queue_name, row):
        return RetriableWalkerEvent(self, queue_name, row)

    def tag_event_done(self, event):
        if event.id in self.status_map:
            del self.status_map[event.id]

    def tag_event_retry(self, event, retry_time):
        self.status_map[event.id] = (EV_RETRY, retry_time)

    def get_status(self, event):
        return self.status_map.get(event.id, (EV_DONE, 0))[0]

    def iter_status(self):
        for res in self.status_map.iteritems():
            yield res


class Consumer(BaseConsumer):
    """Normal consumer base class.
    Can retry events
    """

    _batch_walker_class = RetriableBatchWalker

    def _make_event(self, queue_name, row):
        return RetriableEvent(queue_name, row)

    def _flush_retry(self, curs, batch_id, list):
        """Tag retry events."""

        retry = 0
        if self.pgq_lazy_fetch:
            for ev_id, stat in list.iter_status():
                if stat[0] == EV_RETRY:
                    self._tag_retry(curs, batch_id, ev_id, stat[1])
                    retry += 1
                elif stat[0] != EV_DONE:
                    raise Exception("Untagged event: id=%d" % ev_id)
        else:
            for ev in list:
                if ev._status == EV_RETRY:
                    self._tag_retry(curs, batch_id, ev.id, ev.retry_time)
                    retry += 1
                elif ev._status != EV_DONE:
                    raise Exception("Untagged event: (id=%d, type=%s, data=%s, ex1=%s" % (
                                    ev.id, ev.type, ev.data, ev.extra1))

        # report weird events
        if retry:
            self.stat_increase('retry-events', retry)

    def _finish_batch(self, curs, batch_id, list):
        """Tag events and notify that the batch is done."""

        self._flush_retry(curs, batch_id, list)

        super(Consumer, self)._finish_batch(curs, batch_id, list)

    def _tag_retry(self, cx, batch_id, ev_id, retry_time):
        """Tag event for retry. (internal)"""
        cx.execute("select pgq.event_retry(%s, %s, %s)",
                    [batch_id, ev_id, retry_time])
