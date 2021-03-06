---
title: Foundations - Module
---

# Modules

## Definition

A `Module` has a very specific meaning in the context of this SDK. A `Module` is something between a library and a small state machine. It is built on top of the `BaseApp` abstraction in the sense that all `Module`s must be explicitly interpeted in terms of `BaseApp` in order to compile the application. The full type definition is

~~~ haskell ignore
data Module (name :: Symbol) (h :: *) (q :: *) (s :: EffectRow) (r :: EffectRow) = Module
  { moduleTxDeliverer :: T.RouteTx h r 'DeliverTx
  , moduleTxChecker :: T.RouteTx h r 'CheckTx
  , moduleQueryServer :: Q.RouteQ q r
  , moduleEval :: forall deps. Members BaseAppEffs deps => forall a. Sem (s :& deps) a -> Sem deps a
  }
~~~

where the type parameters

- `name` is the name of the module, e.g. `"bank"`.
- `h` is the transaction router api type.
- `q` is the query api type for querying state in the url format (more on this later).  
- `s` is the set of effects introduced by this module.
- `r` is the global set of effects that this module will run in when part of a larger application (more on this later).

Below that line we see the fields for the `Module` data type, where

  - `moduleTxDeliverer` specifies how the module processes transactions in order to update the application state during `deliverTx` messages. 
  - `moduleTxChecker` is used during `checkTx` messages to check if a transaction in the mempool is a valid transaction.
  - `moduleQueryServer` is responsible for handling queries for application state from the `query` message.
  - `moduleEval` is the natural transformation that specifies how to interpet the `Module` in terms of `BaseApp`.

Note that in the event that a `Module` is _abstract_, meaning it doesn't have any messages to respond to, then we have `msg ~ Void`.

## Composition

`Module`s are meant to be composed to create larger applications. We will see examples of this with the `Nameservice` application. The way to do this is easy, as the `Modules` data type allows you to simply combine them in a heterogeneous list:

~~~ haskell ignore
data Modules (ms :: [*]) r where
    NilModules :: Modules '[] r
    (:+) :: Module name msg api s r -> Modules ms r -> Modules (Module name msg api s r  ': ms) r
~~~

When you are ready to create your application, you simply specify a value of type `Modules` and some other configuration data, and the SDK will create an `App` for you.
