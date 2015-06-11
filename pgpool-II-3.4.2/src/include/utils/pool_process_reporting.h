/* -*-pgsql-c-*- */
/*
 *
 * $Header$
 *
 * pgpool: a language independent connection pool server for PostgreSQL
 * written by Tatsuo Ishii
 *
 * Copyright (c) 2003-2012	PgPool Global Development Group
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
 * pool_process_reporting.h.: header file for pool_process_reporting.c
 *
 */

#ifndef POOL_PROCESS_REPORTING_H
#define POOL_PROCESS_REPORTING_H

extern void send_row_description(POOL_CONNECTION *frontend, POOL_CONNECTION_POOL *backend,
							short num_fields, char **field_names);
extern void send_complete_and_ready(POOL_CONNECTION *frontend, POOL_CONNECTION_POOL *backend, const int num_rows);
extern POOL_REPORT_CONFIG* get_config(int *nrows);
extern POOL_REPORT_POOLS* get_pools(int *nrows);
extern POOL_REPORT_PROCESSES* get_processes(int *nrows);
extern POOL_REPORT_NODES* get_nodes(int *nrows);
extern POOL_REPORT_VERSION* get_version(void);
extern void config_reporting(POOL_CONNECTION *frontend, POOL_CONNECTION_POOL *backend);
extern void pools_reporting(POOL_CONNECTION *frontend, POOL_CONNECTION_POOL *backend);
extern void processes_reporting(POOL_CONNECTION *frontend, POOL_CONNECTION_POOL *backend);
extern void nodes_reporting(POOL_CONNECTION *frontend, POOL_CONNECTION_POOL *backend);
extern void version_reporting(POOL_CONNECTION *frontend, POOL_CONNECTION_POOL *backend);
extern void cache_reporting(POOL_CONNECTION *frontend, POOL_CONNECTION_POOL *backend);

#endif
