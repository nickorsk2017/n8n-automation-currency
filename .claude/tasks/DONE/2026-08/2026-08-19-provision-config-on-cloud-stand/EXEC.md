# EXEC — 2026-08-19-provision-config-on-cloud-stand

## v1

Applied through the n8n connector (project 7be3175KDEz3HrYS,
nickdevstartup.app.n8n.cloud), not the Makefile: this environment has no route
to run `make setup` against that stand.

1. Created data table `config` (id p0P74SyeGh1NBwyA) with `config_key`,
   `config_value`; inserted one row `base_currency = USD`. (R1)
2. Updated loader iBdFv2bTfVR7chbE to the repository state: removed
   `Set - Loader Config`, added `Data Table - Get Base Currency Config`
   (alwaysOutputData) and `IF - Base Currency Configured`, rewired
   trigger -> config -> gate -> HTTP with the gate's false output joining the
   existing error branch, repointed the HTTP query parameter and both Code
   nodes. (R2)
3. Manual execution 187: succeeded. The config node returned
   `config_value = USD`, the gate took its true output, and 33 rows were built
   and upserted with `base_currency: USD`. Live proof of the acceptance the
   previous task could only reason about.
4. Published the draft — before this the active (scheduled) version was still
   the one holding `Set - Loader Config`, so the 06:00 run would have used the
   old graph.

No repository file was touched. (R3)

### Pre-existing divergence found, not touched
The live loader differs from `workflows/currency-rate-loader.json` in ways that
predate this task and are outside its requirements: `Data Table - Upsert Rate
Row` references `currency_rates` by id (`mode: "id"`) where the file uses
`mode: "name"`; the trigger and several nodes carry older `notes` text; some
node positions differ. Raised for the Engineer as a separate drift task rather
than silently reconciled here.
