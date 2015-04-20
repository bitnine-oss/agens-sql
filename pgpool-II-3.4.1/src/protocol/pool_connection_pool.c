/* -*-pgsql-c-*- */
/*
 * $Header$
 *
 * pgpool: a language independent connection pool server for PostgreSQL
 * written by Tatsuo Ishii
 *
 * Copyright (c) 2003-2014	PgPool Global Development Group
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose and without fee is hereby
 * granted, provided that the above copyright notice appear in all
 * copies and that both that copyright notice and this permission
 * notice appear in supporting documentation, and that the name of the
 * author not be used in advertising or publicity pertaining to
 * distribution of the software without specific, written prior
 * permission. The author makes no representations about the
 * suitability of this software for any purpose.  It is provided "as
 * is" without express or implied warranty.
 *
 * pool_connection_pool.c: connection pool stuff
 */
#include "config.h"

#include <sys/types.h>
#include <sys/time.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <sys/un.h>
#ifdef HAVE_SYS_SELECT_H
#include <sys/select.h>
#endif
#ifdef HAVE_NETINET_TCP_H
#include <netinet/tcp.h>
#endif
#include <netdb.h>

#include <stdio.h>
#include <errno.h>
#include <signal.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>

#include "pool.h"
#include "utils/pool_stream.h"
#include "utils/palloc.h"
#include "pool_config.h"
#include "utils/elog.h"
#include "utils/memutils.h"
#include "context/pool_process_context.h"

static int pool_index;	/* Active pool index */
POOL_CONNECTION_POOL *pool_connection_pool;	/* connection pool */
volatile sig_atomic_t backend_timer_expired = 0; /* flag for connection closed timer is expired */
volatile sig_atomic_t health_check_timer_expired;		/* non 0 if health check timer expired */
static POOL_CONNECTION_POOL_SLOT *create_cp(POOL_CONNECTION_POOL_SLOT *cp, int slot);
static POOL_CONNECTION_POOL *new_connection(POOL_CONNECTION_POOL *p);
static int check_socket_status(int fd);
static bool connect_with_timeout(int fd, struct addrinfo *walk, char *host, int port, bool retry);

/*
* initialize connection pools. this should be called once at the startup.
*/
int pool_init_cp(void)
{
	int i;
	MemoryContext oldContext = MemoryContextSwitchTo(TopMemoryContext);

	pool_connection_pool = (POOL_CONNECTION_POOL *)palloc(sizeof(POOL_CONNECTION_POOL)*pool_config->max_pool);
	memset(pool_connection_pool, 0, sizeof(POOL_CONNECTION_POOL)*pool_config->max_pool);

	for (i = 0; i < pool_config->max_pool; i++)
	{
		pool_connection_pool[i].info = pool_coninfo(pool_get_process_context()->proc_id, i, 0);
		memset(pool_connection_pool[i].info, 0, sizeof(ConnectionInfo) * MAX_NUM_BACKENDS);
	}
    MemoryContextSwitchTo(oldContext);
	return 0;
}

/*
* find connection by user and database
*/
POOL_CONNECTION_POOL *pool_get_cp(char *user, char *database, int protoMajor, int check_socket)
{
#ifdef HAVE_SIGPROCMASK
	sigset_t oldmask;
#else
	int	oldmask;
#endif

	int i, freed = 0;
	ConnectionInfo *info;

	POOL_CONNECTION_POOL *connection_pool = pool_connection_pool;

	if (connection_pool == NULL)
	{
        /* if no connection pool exists we have no reason to live */
        ereport(ERROR,
                (return_code(2),
                 errmsg("unable to get connection"),
                  errdetail("connection pool is not initialized")));
	}

	POOL_SETMASK2(&BlockSig, &oldmask);

	for (i=0;i<pool_config->max_pool;i++)
	{
		if (MASTER_CONNECTION(connection_pool) &&
			MASTER_CONNECTION(connection_pool)->sp &&
			MASTER_CONNECTION(connection_pool)->sp->major == protoMajor &&
			MASTER_CONNECTION(connection_pool)->sp->user != NULL &&
			strcmp(MASTER_CONNECTION(connection_pool)->sp->user, user) == 0 &&
			strcmp(MASTER_CONNECTION(connection_pool)->sp->database, database) == 0)
		{
			int sock_broken = 0;
			int j;

			/* mark this connection is under use */
			MASTER_CONNECTION(connection_pool)->closetime = 0;
			for (j=0;j<NUM_BACKENDS;j++)
			{
				connection_pool->info[j].counter++;
			}
			POOL_SETMASK(&oldmask);

			if (check_socket)
			{
				for (j=0;j<NUM_BACKENDS;j++)
				{
					if (!VALID_BACKEND(j))
						continue;

					if  (CONNECTION_SLOT(connection_pool, j))
					{
						sock_broken = check_socket_status(CONNECTION(connection_pool, j)->fd);
						if (sock_broken < 0)
							break;
					}
					else
					{
						sock_broken = -1;
						break;
					}
				}

				if (sock_broken < 0)
				{
					ereport(LOG,
						(errmsg("connection closed."),
							 errdetail("retry to create new connection pool")));

					for (j=0;j<NUM_BACKENDS;j++)
					{
						if (!VALID_BACKEND(j) || (CONNECTION_SLOT(connection_pool, j) == NULL))
							continue;

						if (!freed)
						{
							pool_free_startup_packet(CONNECTION_SLOT(connection_pool, j)->sp);
                            CONNECTION_SLOT(connection_pool, j)->sp = NULL;

							freed = 1;
						}

						pool_close(CONNECTION(connection_pool, j));
						pfree(CONNECTION_SLOT(connection_pool, j));
					}
					info = connection_pool->info;
					memset(connection_pool, 0, sizeof(POOL_CONNECTION_POOL));
					connection_pool->info = info;
					memset(connection_pool->info, 0, sizeof(ConnectionInfo) * MAX_NUM_BACKENDS);
					POOL_SETMASK(&oldmask);
					return NULL;
				}
			}
			POOL_SETMASK(&oldmask);
			pool_index = i;
			return connection_pool;
		}
		connection_pool++;
	}

	POOL_SETMASK(&oldmask);
	return NULL;
}

/*
 * disconnect and release a connection to the database
 */
void pool_discard_cp(char *user, char *database, int protoMajor)
{
	POOL_CONNECTION_POOL *p = pool_get_cp(user, database, protoMajor, 0);
	ConnectionInfo *info;
	int i, freed = 0;

	if (p == NULL)
	{
		ereport(LOG,
			(errmsg("cannot get connection pool for user: \"%s\" database: \"%s\", while discarding connection pool", user, database)));
		return;
	}

	for (i=0;i<NUM_BACKENDS;i++)
	{
		if (!VALID_BACKEND(i))
			continue;

		if (!freed)
		{
			pool_free_startup_packet(CONNECTION_SLOT(p, i)->sp);
			freed = 1;
		}
        CONNECTION_SLOT(p, i)->sp = NULL;
		pool_close(CONNECTION(p, i));
		pfree(CONNECTION_SLOT(p, i));
	}

	info = p->info;
	memset(p, 0, sizeof(POOL_CONNECTION_POOL));
	p->info = info;
	memset(p->info, 0, sizeof(ConnectionInfo) * MAX_NUM_BACKENDS);
}


/*
* create a connection pool by user and database
*/
POOL_CONNECTION_POOL *pool_create_cp(void)
{
	int i, freed = 0;
	time_t closetime;
	POOL_CONNECTION_POOL *oldestp;
	POOL_CONNECTION_POOL *ret;
	ConnectionInfo *info;

	POOL_CONNECTION_POOL *p = pool_connection_pool;
    /* if no connection pool exists we have no reason to live */
	if (p == NULL)
        ereport(ERROR,
			(return_code(2),
				 errmsg("unable to create connection"),
					errdetail("connection pool is not initialized")));

	for (i=0;i<pool_config->max_pool;i++)
	{
		if (MASTER_CONNECTION(p) == NULL)
		{
			ret = new_connection(p);
			if (ret)
				pool_index = i;
			return ret;
		}
		p++;
	}
	ereport(DEBUG1,
		(errmsg("creating connection pool"),
			 errdetail("no empty connection slot was found")));

	/*
	 * no empty connection slot was found. look for the oldest connection and discard it.
	 */
	oldestp = p = pool_connection_pool;
	closetime = MASTER_CONNECTION(p)->closetime;
	pool_index = 0;

	for (i=0;i<pool_config->max_pool;i++)
	{
		ereport(DEBUG1,
			(errmsg("creating connection pool"),
				errdetail("user: %s database: %s closetime: %ld",
					   MASTER_CONNECTION(p)->sp->user,
					   MASTER_CONNECTION(p)->sp->database,
					   MASTER_CONNECTION(p)->closetime)));

		if (MASTER_CONNECTION(p)->closetime < closetime)
		{
			closetime = MASTER_CONNECTION(p)->closetime;
			oldestp = p;
			pool_index = i;
		}
		p++;
	}

	p = oldestp;
	pool_send_frontend_exits(p);

	ereport(DEBUG1,
		(errmsg("creating connection pool"),
			errdetail("discarding old %zd th connection. user: %s database: %s",
				   oldestp - pool_connection_pool,
				   MASTER_CONNECTION(p)->sp->user,
				   MASTER_CONNECTION(p)->sp->database)));

	for (i=0;i<NUM_BACKENDS;i++)
	{
		if (!VALID_BACKEND(i))
			continue;

		if (!freed)
		{
			pool_free_startup_packet(CONNECTION_SLOT(p, i)->sp);
            CONNECTION_SLOT(p, i)->sp = NULL;

			freed = 1;
		}

		pool_close(CONNECTION(p, i));
		pfree(CONNECTION_SLOT(p, i));
	}

	info = p->info;
	memset(p, 0, sizeof(POOL_CONNECTION_POOL));
	p->info = info;
	memset(p->info, 0, sizeof(ConnectionInfo) * MAX_NUM_BACKENDS);

	ret = new_connection(p);
	return ret;
}

/*
 * set backend connection close timer
 */
void pool_connection_pool_timer(POOL_CONNECTION_POOL *backend)
{
	POOL_CONNECTION_POOL *p = pool_connection_pool;
	int i;

	ereport(DEBUG1,
		(errmsg("setting backend connection close timer"),
			 errdetail("close time %ld", time(NULL))));

	MASTER_CONNECTION(backend)->closetime = time(NULL);		/* set connection close time */

	if (pool_config->connection_life_time == 0)
		return;

	/* look for any other timeout */
	for (i=0;i<pool_config->max_pool;i++, p++)
	{
		if (!MASTER_CONNECTION(p))
			continue;
		if (!MASTER_CONNECTION(p)->sp)
			continue;
		if (MASTER_CONNECTION(p)->sp->user == NULL)
			continue;

		if (p != backend && MASTER_CONNECTION(p)->closetime)
			return;
	}

	/* no other timer found. set my timer */
	ereport(DEBUG1,
		(errmsg("setting backend connection close timer"),
			 errdetail("setting alarm after %d seconds", pool_config->connection_life_time)));

	pool_signal(SIGALRM, pool_backend_timer_handler);
	alarm(pool_config->connection_life_time);
}

/*
 * backend connection close timer handler
 */
RETSIGTYPE pool_backend_timer_handler(int sig)
{
	backend_timer_expired = 1;
}

void pool_backend_timer(void)
{
#define TMINTMAX 0x7fffffff

	POOL_CONNECTION_POOL *p = pool_connection_pool;
	int i, j;
	time_t now;
	time_t nearest = TMINTMAX;
	ConnectionInfo *info;

	POOL_SETMASK(&BlockSig);

	now = time(NULL);

	ereport(DEBUG1,
		(errmsg("backend timer handler called at%ld", now)));

	for (i=0;i<pool_config->max_pool;i++, p++)
	{
		if (!MASTER_CONNECTION(p))
			continue;
		if (!MASTER_CONNECTION(p)->sp)
			continue;
		if (MASTER_CONNECTION(p)->sp->user == NULL)
			continue;

		/* timer expire? */
		if (MASTER_CONNECTION(p)->closetime)
		{
			int freed = 0;

			ereport(DEBUG1,
				(errmsg("backend timer handler called"),
					errdetail("expire time: %ld",
						   MASTER_CONNECTION(p)->closetime+pool_config->connection_life_time)));

			if (now >= (MASTER_CONNECTION(p)->closetime+pool_config->connection_life_time))
			{
				/* discard expired connection */
				ereport(DEBUG1,
					(errmsg("backend timer handler called"),
						errdetail("expired user: \"%s\" database: \"%s\"",
							   MASTER_CONNECTION(p)->sp->user, MASTER_CONNECTION(p)->sp->database)));
				pool_send_frontend_exits(p);

				for (j=0;j<NUM_BACKENDS;j++)
				{
					if (!VALID_BACKEND(j))
						continue;

					if (!freed)
					{
						pool_free_startup_packet(CONNECTION_SLOT(p, j)->sp);
						freed = 1;
					}
                    CONNECTION_SLOT(p, j)->sp = NULL;
					pool_close(CONNECTION(p, j));
					pfree(CONNECTION_SLOT(p, j));
				}
				info = p->info;
				memset(p, 0, sizeof(POOL_CONNECTION_POOL));
				p->info = info;
				memset(p->info, 0, sizeof(ConnectionInfo) * MAX_NUM_BACKENDS);
			}
			else
			{
				/* look for nearest timer */
				if (MASTER_CONNECTION(p)->closetime < nearest)
					nearest = MASTER_CONNECTION(p)->closetime;
			}
		}
	}

	/* any remaining timer */
	if (nearest != TMINTMAX)
	{
		nearest = pool_config->connection_life_time - (now - nearest);
		if (nearest <= 0)
		  nearest = 1;
		pool_signal(SIGALRM, pool_backend_timer_handler);
		alarm(nearest);
	}

	POOL_SETMASK(&UnBlockSig);
}

/*
 * connect to postmaster through INET domain socket
 */
int connect_inet_domain_socket(int slot, bool retry)
{
	char *host;
	int port;

	host = pool_config->backend_desc->backend_info[slot].backend_hostname;
	port = pool_config->backend_desc->backend_info[slot].backend_port;

	return connect_inet_domain_socket_by_port(host, port, retry);
}

/*
 * connect to postmaster through UNIX domain socket
 */
int connect_unix_domain_socket(int slot, bool retry)
{
	int port;
	char *socket_dir;

	port = pool_config->backend_desc->backend_info[slot].backend_port;
	socket_dir = pool_config->backend_desc->backend_info[slot].backend_hostname;

	return connect_unix_domain_socket_by_port(port, socket_dir, retry);
}

/*
 * Connect to PostgreSQL server by using UNIX domain socket.
 * If retry is true, retry to call connect() upon receiving EINTR error.
 */
int connect_unix_domain_socket_by_port(int port, char *socket_dir, bool retry)
{
	struct sockaddr_un addr;
	int fd;
	int len;

	fd = socket(AF_UNIX, SOCK_STREAM, 0);
	if (fd == -1)
	{
		ereport(LOG,
			(errmsg("failed to connect to PostgreSQL server by unix domain socket"),
				 errdetail("create socket failed with error \"%s\"", strerror(errno))));
		return -1;
	}

	memset((char *) &addr, 0, sizeof(addr));
	addr.sun_family = AF_UNIX;
	snprintf(addr.sun_path, sizeof(addr.sun_path), "%s/.s.PGSQL.%d", socket_dir, port);
	len = sizeof(struct sockaddr_un);

	for (;;)
	{
		if (exit_request)		/* exit request already sent */
		{
			ereport(LOG,
				(errmsg("failed to connect to PostgreSQL server by unix domain socket"),
					 errdetail("exit request has been sent")));
			close(fd);
			return -1;
		}

		if (connect(fd, (struct sockaddr *)&addr, len) < 0)
		{
			if ((errno == EINTR && retry) || errno == EAGAIN)
				continue;
			close(fd);
			ereport(LOG,
				(errmsg("failed to connect to PostgreSQL server by unix domain socket"),
					 errdetail("connect to \"%s\" failed with error \"%s\"",addr.sun_path, strerror(errno))));

			return -1;
		}
		break;
	}

	return fd;
}

/*
 * Connet to backend using pool_config->connect_timeout.
 *
 * fd: the socket
 * walk: backend address to connect
 * host and port: backend hostname and port number. Only for error message
 * purpose.
 * retry: true if need to retry
 */
static bool connect_with_timeout(int fd, struct addrinfo *walk, char *host, int port, bool retry)
{
	struct timeval *tm;
	struct timeval timeout;
	fd_set rset, wset;
	int sts;
	int error;
	socklen_t socklen;

	pool_set_nonblock(fd);

	for (;;)
	{
		if (exit_request)		/* exit request already sent */
		{
			ereport(LOG,
				(errmsg("failed to connect to PostgreSQL server on \"%s:%d\" using INET socket",host,port),
					 errdetail("exit request has been sent")));
			close(fd);
			return false;
		}

		if (health_check_timer_expired && getpid() == mypid)		/* has health check timer expired */
		{
			ereport(LOG,
				(errmsg("failed to connect to PostgreSQL server on \"%s:%d\" using INET socket",host,port),
					 errdetail("health check timer expired")));
			close(fd);
			return false;
		}

		if (connect(fd, walk->ai_addr, walk->ai_addrlen) < 0)
		{
			if (errno == EISCONN)
			{
				/* Socket is already connected */
				break;
			}

			if ((errno == EINTR && retry) || errno == EAGAIN)
				continue;

			/*
			 * If error was "connect(2) is in progress", then wait for
			 * completion.  Otherwise error out.
			 */
			if (errno != EINPROGRESS && errno != EALREADY)
			{
				ereport(LOG,
					(errmsg("failed to connect to PostgreSQL server on \"%s:%d\" with error \"%s\"",host,port,strerror(errno))));
				return false;
			}

			if (pool_config->connect_timeout == 0)
				tm = NULL;
			else
			{
				tm = &timeout;
				timeout.tv_sec = pool_config->connect_timeout/1000;
				if (timeout.tv_sec == 0)
				{
					timeout.tv_usec = pool_config->connect_timeout*1000;
				}
				else
				{
					timeout.tv_usec = (pool_config->connect_timeout - timeout.tv_sec*1000)*1000;
				}
			}

			FD_ZERO(&rset);
			FD_SET(fd, &rset);	
			FD_ZERO(&wset);
			FD_SET(fd, &wset);
			sts = select(fd+1, &rset, &wset, NULL, tm);

			if (sts == 0)
			{
				/* select timeout */
				if (retry)
				{
					ereport(LOG,
						(errmsg("trying connecting to PostgreSQL server on \"%s:%d\" by INET socket",host,port),
							 errdetail("timed out. retrying...")));
					continue;
				}
				else
				{
					ereport(LOG,
						(errmsg("failed to connect to PostgreSQL server on \"%s:%d\", timed out",host,port)));
					return false;
				}
			}
			else if (sts > 0)
			{
				/*
				 * If read data or write data was set, either connect
				 * succeeded or error.  We need to figure it out. This
				 * is the hardest part in using non blocking
				 * connect(2).  See W. Richar Stevens's "UNIX Network
				 * Programming: Volume 1, Second Edition" section
				 * 15.4.
				 */
				if (FD_ISSET(fd, &rset) || FD_ISSET(fd, &wset))
				{
					error = 0;
					socklen = sizeof(error);
					if (getsockopt(fd, SOL_SOCKET, SO_ERROR, &error, &socklen) < 0)
					{
						/* Solaris returns error in this case */
						ereport(LOG,
							(errmsg("failed to connect to PostgreSQL server on \"%s:%d\", getsockopt() failed with error \"%s\"",host,port,strerror(errno))));

						return false;
					}

					/* Non Solaris case */
					if (error != 0)
					{
						ereport(LOG,
								(errmsg("failed to connect to PostgreSQL server on \"%s:%d\", getsockopt() detected error \"%s\"",host,port,strerror(errno))));
						return false;
					}
				}
				else
				{
					ereport(LOG,
							(errmsg("failed to connect to PostgreSQL server on \"%s:%d\", both read data and write data was not set",host,port)));

					return false;
				}
			}
			else		/* select returns error */
			{
				if((errno == EINTR && retry) || errno == EAGAIN)
				{
					ereport(LOG,
						(errmsg("trying to connect to PostgreSQL server on \"%s:%d\" using INET socket",host,port),
							 errdetail("select() interrupted. retrying...")));
					continue;
				}
				ereport(LOG,
					(errmsg("failed to connect to PostgreSQL server on \"%s:%d\" using INET socket",host,port),
						 errdetail("select() system call interrupted")));
				close(fd);
				return false;
			}
		}
		break;
	}

	pool_unset_nonblock(fd);
	return true;
}

/*
 * Connect to PostgreSQL server by using INET domain socket.
 * If retry is true, retry to call connect() upon receiving EINTR error.
 */
int connect_inet_domain_socket_by_port(char *host, int port, bool retry)
{
	int fd = -1;
	int on = 1;
	char *portstr;
	int ret;
	struct addrinfo *res;
	struct addrinfo *walk;
	struct addrinfo hints;

	/* getaddrinfo() requires a string because it also accepts service names, such as "http". */
	if (asprintf(&portstr, "%d", port) == -1)
	{
		ereport(WARNING,
			(errmsg("failed to connect to PostgreSQL server, asprintf() failed with error \"%s\"",strerror(errno))));

		return -1;
	}

	memset(&hints, 0, sizeof(struct addrinfo));
	hints.ai_family = PF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;

	if ((ret = getaddrinfo(host, portstr, &hints, &res)) != 0)
	{
		ereport(WARNING,
			(errmsg("failed to connect to PostgreSQL server, getaddrinfo() failed with error \"%s\"",gai_strerror(ret))));

		free(portstr);
		return -1;
	}

	free(portstr);

	for (walk = res; walk != NULL; walk = walk->ai_next)
	{
		fd = socket(walk->ai_family, walk->ai_socktype, walk->ai_protocol);
		if (fd < 0)
		{
			ereport(WARNING,
					(errmsg("failed to connect to PostgreSQL server, socket() failed with error \"%s\"",strerror(errno))));
			continue;
		}

		/* set nodelay */
		if (setsockopt(fd, IPPROTO_TCP, TCP_NODELAY,
					   (char *) &on,
					   sizeof(on)) < 0)
		{
			ereport(WARNING,
					(errmsg("failed to connect to PostgreSQL server, setsockopt() failed with error \"%s\"",strerror(errno))));

			close(fd);
			freeaddrinfo(res);
			return -1;
		}

		if (!connect_with_timeout(fd, walk, host, port, retry))
		{
			close(fd);
			fd = -1;
			continue;
		}

		freeaddrinfo(res);
		return fd;
	}

	freeaddrinfo(res);
	return -1;
}
 
/*
 * create connection pool
 */
static POOL_CONNECTION_POOL_SLOT *create_cp(POOL_CONNECTION_POOL_SLOT *cp, int slot)
{
	BackendInfo *b = &pool_config->backend_desc->backend_info[slot];
	int fd;

	if (*b->backend_hostname == '/')
	{
		fd = connect_unix_domain_socket(slot, TRUE);
	}
	else
	{
		fd = connect_inet_domain_socket(slot, TRUE);
	}

	if (fd < 0)
		return NULL;

	cp->sp = NULL;
	cp->con = pool_open(fd,true);
	cp->closetime = 0;
	return cp;
}

/*
 * create actual connections to backends
 * new connection resides in TopMemoryContext
 */
static POOL_CONNECTION_POOL *new_connection(POOL_CONNECTION_POOL *p)
{
	POOL_CONNECTION_POOL_SLOT *s;
	int active_backend_count = 0;
	int i;

    MemoryContext oldContext = MemoryContextSwitchTo(TopMemoryContext);
    
	for (i=0;i<NUM_BACKENDS;i++)
	{
		ereport(DEBUG1,
			(errmsg("creating new connection to backend"),
				 errdetail("connecting %d backend", i)));

		if (!VALID_BACKEND(i))
		{
			ereport(DEBUG1,
				(errmsg("creating new connection to backend"),
					errdetail("skipping backend slot %d because backend_status = %d",
						   i, BACKEND_INFO(i).backend_status)));
			continue;
		}

		s = palloc(sizeof(POOL_CONNECTION_POOL_SLOT));

		if (create_cp(s, i) == NULL)
		{
			/* If fail_over_on_backend_error is true, do failover.
			 * Otherwise, just exit this session.
			 */
			if (pool_config->fail_over_on_backend_error)
			{
				notice_backend_error(i);
			}
			else
			{
				ereport(LOG,
					(errmsg("creating new connection to backend"),
						 errdetail("not executing failover because fail_over_on_backend_error is off")));
			}
			child_exit(1);
		}

		p->info[i].create_time = time(NULL);
		p->slots[i] = s;

		pool_init_params(&s->con->params);
	
		BACKEND_INFO(i).backend_status = CON_UP;
		active_backend_count++;
	}

    MemoryContextSwitchTo(oldContext);

	if (active_backend_count > 0)
	{
		return p;
	}

	return NULL;
}

/* check_socket_status()
 * RETURN: 0 => OK
 *        -1 => broken socket.
 */
static int check_socket_status(int fd)
{
	fd_set rfds;
	int result;
	struct timeval t;

	for (;;)
	{
		FD_ZERO(&rfds);
		FD_SET(fd, &rfds);

		t.tv_sec = t.tv_usec = 0;

		result = select(fd+1, &rfds, NULL, NULL, &t);
		if (result < 0 && errno == EINTR)
		{
			continue;
		}
		else
		{
			return (result == 0 ? 0 : -1);
		}
	}

	return -1;
}

/*
 * Return current used index (i.e. frontend connected)
 */
int pool_pool_index(void)
{
	return pool_index;
}
