### Environments
Athena uses the environmental variable `ATHENA_ENV` to determine the current environment.  This variable determines which log handlers are enabled by default, and which configuration object to use.  If no ENV variable is defined, the default environment is `development`. The method `Athena.environment` can be used to return the application's current environment.  Custom environments can also be used, just be sure to update your `athena.yml`.  




