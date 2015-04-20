/* -*-pgsql-c-*- */
/*
 * $Header$
 *
 * pgpool: a language independent connection pool server for PostgreSQL
 * written by Tatsuo Ishii
 *
 * Copyright (c) 2003-2013	PgPool Global Development Group
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
 * pg_md5 command main
 *
 */
#include "pool.h"
#include "pool_config.h"
#include "auth/pool_passwd.h"
#include "auth/md5.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <termios.h>
#ifdef HAVE_GETOPT_H
#include <getopt.h>
#else
#include "utils/getopt_long.h"
#endif
#include <pwd.h>
#include <libgen.h>

/* Maximum number of characters allowed for input. */
#define MAX_INPUT_SIZE	MAX_USER_NAME_LEN

static void	print_usage(const char prog[], int exit_code);
static void	set_tio_attr(int enable);
static void update_pool_passwd(char *conf_file, char *username, char *password);

int
main(int argc, char *argv[])
{
#define PRINT_USAGE(exit_code)	print_usage(argv[0], exit_code)

	char conf_file[POOLMAXPATHLEN+1];
	char username[MAX_INPUT_SIZE+1];
	int opt;
	int optindex;
	bool md5auth = false;
	bool prompt = false;

	static struct option long_options[] = {
		{"help", no_argument, NULL, 'h'},
		{"prompt", no_argument, NULL, 'p'},
		{"md5auth", no_argument, NULL, 'm'},
		{"username", required_argument, NULL, 'u'},
		{"config-file", required_argument, NULL, 'f'},
		{NULL, 0, NULL, 0}
	};

	snprintf(conf_file, sizeof(conf_file), "%s/%s", DEFAULT_CONFIGDIR, POOL_CONF_FILE_NAME);

	/* initialize username buffer with zeros so that we can use strlen on it later
	   to check if a username was given on the command line
	 */
	memset(username, 0, MAX_INPUT_SIZE+1);

    while ((opt = getopt_long(argc, argv, "hpmf:u:", long_options, &optindex)) != -1)
	{
		switch (opt)
		{
			case 'p':    /* prompt for password */
				prompt = true;
				break;

			case 'm':	/* produce md5 authentication password */
				md5auth = true;
				break;

			case 'f':	/* specify configuration file */
				if (!optarg)
				{
					PRINT_USAGE(EXIT_SUCCESS);
				}
				strlcpy(conf_file, optarg, sizeof(conf_file));
				break;

			case 'u':
				if (!optarg)
				{
					PRINT_USAGE(EXIT_SUCCESS);
				}
				/* check the input limit early */
				if (strlen(optarg) > MAX_INPUT_SIZE)
				{
					fprintf(stderr, "Error: input exceeds maximum username length!\n\n");
					exit(EXIT_FAILURE);
				}
				strlcpy(username, optarg, sizeof(username));
				break;

			default:
				PRINT_USAGE(EXIT_SUCCESS);
				break;
		}
	}				

	/* Prompt for password. */
	if (prompt)
	{
		char	 md5[MD5_PASSWD_LEN+1];
		char	 buf[MAX_INPUT_SIZE+1];
		int		 len;

		set_tio_attr(1);
		printf("password: ");
		if (!fgets(buf, (MAX_INPUT_SIZE+1), stdin))
		{
			int eno = errno;

			fprintf(stderr, "Couldn't read input from stdin. (fgets(): %s)",
					strerror(eno));

			exit(EXIT_FAILURE);
		}
		printf("\n");
		set_tio_attr(0);

		/* Remove LF at the end of line, if there is any. */
		len = strlen(buf);
		if (len > 0 && buf[len-1] == '\n')
		{
			buf[len-1] = '\0';
			len--;
		}

		if (md5auth)
		{
			update_pool_passwd(conf_file, username, buf);
		}
		else
		{
			pool_md5_hash(buf, len, md5);
			printf("%s\n", md5);
		}
	}

	/* Read password from argv. */
	else
	{
		char	md5[POOL_PASSWD_LEN+1];
		int		len;

		if (optind >= argc)
		{
			PRINT_USAGE(EXIT_FAILURE);
		}
			
		len = strlen(argv[optind]);

		if (len > MAX_INPUT_SIZE)
		{
			fprintf(stderr, "Error: Input exceeds maximum password length!\n\n");
			PRINT_USAGE(EXIT_FAILURE);
		}

		if (md5auth)
		{
			update_pool_passwd(conf_file, username, argv[optind]);
		}
		else
		{
			pool_md5_hash(argv[optind], len, md5);
			printf("%s\n", md5);
		}
	}

	return EXIT_SUCCESS;
}

static void update_pool_passwd(char *conf_file, char *username, char *password)
{
	struct passwd *pw;
	char	 md5[POOL_PASSWD_LEN+1];
	char pool_passwd[POOLMAXPATHLEN+1];
	char dirnamebuf[POOLMAXPATHLEN+1];
	char *dirp;

	if (pool_init_config())
	{
		fprintf(stderr, "pool_init_config() failed\n\n");
		exit(EXIT_FAILURE);
	}
	if (pool_get_config(conf_file, INIT_CONFIG))
	{
		fprintf(stderr, "Unable to get configuration. Exiting...");
		exit(EXIT_FAILURE);
	}

	strlcpy(dirnamebuf, conf_file, sizeof(dirnamebuf));
	dirp = dirname(dirnamebuf);
	snprintf(pool_passwd, sizeof(pool_passwd), "%s/%s",
			 dirp, pool_config->pool_passwd);
	pool_init_pool_passwd(pool_passwd);

	if (strlen(username))
	{
		/* generate the hash for the given username */
		pg_md5_encrypt(password, username, strlen(username), md5);
		pool_create_passwdent(username, md5);
	}
	else
	{
		/* get the user information from the current uid */
		pw = getpwuid(getuid());
		if (!pw)
		{
			fprintf(stderr, "getpwuid() failed\n\n");
			exit(EXIT_FAILURE);
		}
		pg_md5_encrypt(password, pw->pw_name, strlen(pw->pw_name), md5);
		pool_create_passwdent(pw->pw_name, md5);
	}
	pool_finish_pool_passwd();
}

static void
print_usage(const char prog[], int exit_code)
{
	fprintf(((exit_code == EXIT_SUCCESS) ? stdout : stderr),
			"Usage:\n\
\n\
  %s [OPTIONS]\n\
  %s <PASSWORD>\n\
\n\
  --prompt, -p         Prompt password using standard input.\n\
  --md5auth, -m        Produce md5 authentication password.\n\
  --username, -u USER  When producing a md5 authentication password,\n\
                       create the pool_passwd entry for USER.\n\
  --config-file, -f CONFIG-FILE  Specify pgpool.conf.\n\
  --help, -h           This help menu.\n\
\n\
Warning: At most %d characters are allowed for input.\n\
Warning: Plain password argument is deprecated for security concerns\n\
         and kept for compatibility. Please prefer using password\n\
         prompt.\n",
			prog, prog, MAX_INPUT_SIZE);

	exit(exit_code);
}


static void
set_tio_attr(int set)
{
	struct termios tio;
	static struct termios tio_save;


	if (!isatty(0))
	{
		fprintf(stderr, "stdin is not tty\n");
		exit(EXIT_FAILURE);
	}

	if (set)
	{
		if (tcgetattr(0, &tio) < 0)
		{
			fprintf(stderr, "set_tio_attr(set): tcgetattr failed\n");
			exit(EXIT_FAILURE);
		}

		tio_save = tio;

		tio.c_iflag &= ~(BRKINT|ISTRIP|IXON);
		tio.c_lflag &= ~(ICANON|IEXTEN|ECHO|ECHOE|ECHOK|ECHONL);
		tio.c_cc[VMIN] = 1;
		tio.c_cc[VTIME] = 0;

		if (tcsetattr(0, TCSANOW, &tio) < 0)
		{
			fprintf(stderr, "(set_tio_attr(set): tcsetattr failed\n");
			exit(EXIT_FAILURE);
		}
	}
	else
	{
		if (tcsetattr(0, TCSANOW, &tio_save) < 0)
		{
			fprintf(stderr, "set_tio_attr(reset): tcsetattr failed\n");
			exit(EXIT_FAILURE);
		}
	}
}
