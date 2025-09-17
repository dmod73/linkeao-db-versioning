# Linkeao DB Versioning

Repositorio independiente para versionado de base de datos (SQL).

- Convencion de migraciones: YYYYMMDD_HHMM_<scope>__<resumen>_{up|down}.sql
- Patron: expand -> migrate -> contract (contract solo tras backfill y tests)
- Snapshots por release: /schemas/vX.Y.Z.sql
- Tests SQL: /tests (pgTAP o asserts)

Uso como submodulo:
- git clone --recurse-submodules <app-repo>
- git submodule update --init --recursive
