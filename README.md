### Advanced SQL techniques

This directory showcases some advanced sql techniques. 

The sql found in the notebook postgres.ipynb is from a bootcamp on dataexpert.io found in the [Data Engineer Handbook](https://github.com/DataExpert-io/data-engineer-handbook). Check it out for a complete guid to data engineering.
.

The set-up uses Docker to pulll and modifis the official Postgres Docker image to create my own postgres server. All the standard postgres set-up variables are used, and are loaded from an .env file.

Commands are executed using SQLalchemy or Magic SQL with direct sql commands.

The purpose of this demonstration is to create a slowly changing dimension table that stored information on actors using postgres array structures and custom types.
