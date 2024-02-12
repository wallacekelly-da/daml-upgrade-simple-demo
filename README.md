# Daml Upgrade Demonstration

This repository contains an simple example illustrating usage of the
[Daml Upgrade](https://github.com/DACH-NY/daml-upgrade) tool. It
contains two versions of a test Daml model and scripts that automate
the process of building the models, starting a local test ledger
populated with test data, and then executing the upgrade. There is
also support for a slightly less automated upgrade demonstration
running against a [Daml Hub](https://hub.daml.com) ledger.

## Prerequisite Software

There isn't much software required to make this work, but there are
a few packages you'll need to have installed.

1. [Daml SDK](https://docs.daml.com/getting-started/installation.html)
2. [jq](https://jqlang.github.io/jq/) - (Best installed through whatever
   package manager you use for your OS.)
3. [Docker](https://www.docker.com/get-started/)

## Running Locally

1. Run `./build-base-models-and-codegen.sh` to build the two base Daml
   models and run the upgrade tool's code generation step. (If there
   is already generated code in `upgrade-model`, the existing code
   will not be overwritten.)
2. [Edit the generated code](#modifying-generated-daml) in `upgrade-model`.
3. Run `./build-upgrade-model.sh` to build the edited upgrade model.
4. Run `./start-ledger.sh` to start a local sandbox ledger. This will
   also populate the ledger with 3,000 contracts via a script defined
   in `testv1`.
5. Run `./run-upgrade.sh` to execute the migration. The individual
   steps of the migration will be printed to the terminal, along with
   status messages from the migration process.
6. The test ledger may be stopped with `./stop-ledger.sh`.

The state of the local project directory may be totally reset by running
`./reset.sh`.

The state of the local ledger may be inspected with the following
Navigator command: `daml navigator server localhost 6865
--feature-user-management false`. Be sure you select the role for
`Alice`.

## Running against Daml Hub

Running the upgrade against Daml Hub is largely the same as the local
run, but with two notable exceptions. The first is that the Hub ledger
must be configured manually rather than via an automatic script. The
second is that the upgrade scripts must be configured explicitly to
point to the Hub ledger.

1. The first three steps of the local run should be performed as
   written above. This will result in three `.dar` files in the
   `target` directory.
2. Create a new Ledger in Daml Hub.
3. Upload and deploy the three `.dar` files produced in step 1 to the
   new ledger.
4. Using the "Identities" tab of ledger view within Hub, create a new
   Party named `Alice`. Copy the JWT for this party to a file within
   the project named `conf/alice-hub-jwt.json`.
5. Run `./init-hub-ledger.sh` to load test data into the new
   ledger. The presence of the JWT file will signal this script (and
   the upgrade script) to connect to the Hub ledger rather than the
   local sandbox. You should see both of these script print the ID of
   the Hub ledger.
6. Run `./run-upgrade.sh` to execute the migration. The individual
   steps of the migration will be printed to the terminal, along with
   status messages from the migration process.

The state of the local project directory may be totally reset by
running `./reset.sh`.

The state of the Hub ledger may be inspected using the Hub console's
live data view. Be sure you select the `Alice` party, and note that
the live data view will require querying for specific templates once
the ledger exceeds 50,000 events.

## Modifying Generated Daml

The upgrade tool automatically generates code for modeling the
lifecycle needed to upgrade contracts from one version to the
next. This includes making proposals and gathering required
permissions from ledger, and also the logic required to marshall data
from one version of a Daml model to the next. In cases where this
cannot be done automatically, the generated code includes placeholders
marking where changes need to be made manually. In the case of the
test models, the relevant part of the generated code is as follows:

```
instance DAMLUpgrade Old.NamedPoint New.NamedPoint where
  convert =
    \a -> New.NamedPoint with
            z     = _new_field_z
            owner = a.owner
            x     = a.x
            y     = a.y
            name  = a.name

instance DAMLUpgrade Old.Point New.Point where
  convert =
    \a -> New.Point with
            owner = a.owner
            x     = a.x
            y     = _convert_y a.y
```

The `NamedPoint` contract includes a reference to `_new_field_z`,
where the code generator does not have information needed to populate
a default value into a new field. The `Point` contract includes a
reference to `_convert_y` where it doesn't know how to convert data
from one data type to another. These are both instances of a _typed hole_
in Daml, closely related to the Haskell concept of the
[same name](https://downloads.haskell.org/~ghc/7.10.1/docs/html/users_guide/typed-holes.html).
The preceeding underscore causes the compile to fail and report errors
indicating the expected types of the values in question. These errors
indicate the changes to be made to complete the upgrade model.

In the case of the test models, `_new_field_z` can be replaced with
`0.0` and `_convert_y` can be replaced with `cast`. For the `cast` to
compile, the following import needs to be added: `import DA.Numeric (cast)`.
