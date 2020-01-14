<!doctype html>
<!--
  Minimal Mistakes Jekyll Theme 4.17.2 by Michael Rose
  Copyright 2013-2019 Michael Rose - mademistakes.com | @mmistakes
  Free for personal and commercial use under the MIT license
  https://github.com/mmistakes/minimal-mistakes/blob/master/LICENSE
-->
<html lang="en" class="no-js">
  <head>
    <meta charset="utf-8">

<!-- begin _includes/seo.html --><title>tutorial -</title>
<meta name="description" content="">



<meta property="og:type" content="website">
<meta property="og:locale" content="en_US">
<meta property="og:site_name" content="">
<meta property="og:title" content="tutorial">
<meta property="og:url" content="/hs-abci/tutorial/README.lhs">













<link rel="canonical" href="/hs-abci/tutorial/README.lhs">




<script type="application/ld+json">
  {
    "@context": "https://schema.org",
    
      "@type": "Person",
      "name": null,
      "url": "/hs-abci/"
    
  }
</script>






<!-- end _includes/seo.html -->


<link href="/hs-abci/feed.xml" type="application/atom+xml" rel="alternate" title=" Feed">

<!-- https://t.co/dKP3o1e -->
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<script>
  document.documentElement.className = document.documentElement.className.replace(/\bno-js\b/g, '') + ' js ';
</script>

<!-- For all browsers -->
<link rel="stylesheet" href="/hs-abci/assets/css/main.css">

<!--[if IE]>
  <style>
    /* old IE unsupported flexbox fixes */
    .greedy-nav .site-title {
      padding-right: 3em;
    }
    .greedy-nav button {
      position: absolute;
      top: 0;
      right: 0;
      height: 100%;
    }
  </style>
<![endif]-->



    <!-- start custom head snippets -->

<!-- insert favicons. use https://realfavicongenerator.net/ -->

<!-- end custom head snippets -->

  </head>

  <body class="layout--home">
    <nav class="skip-links">
  <h2 class="screen-reader-text">Skip links</h2>
  <ul>
    <li><a href="#site-nav" class="screen-reader-shortcut">Skip to primary navigation</a></li>
    <li><a href="#main" class="screen-reader-shortcut">Skip to content</a></li>
    <li><a href="#footer" class="screen-reader-shortcut">Skip to footer</a></li>
  </ul>
</nav>

    <!--[if lt IE 9]>
<div class="notice--danger align-center" style="margin: 0;">You are using an <strong>outdated</strong> browser. Please <a href="https://browsehappy.com/">upgrade your browser</a> to improve your experience.</div>
<![endif]-->

    

<div class="masthead">
  <div class="masthead__inner-wrap">
    <div class="masthead__menu">
      <nav id="site-nav" class="greedy-nav">
        
        <a class="site-title" href="/hs-abci/">
          
          
        </a>
        <ul class="visible-links"></ul>
        
        <button class="greedy-nav__toggle hidden" type="button">
          <span class="visually-hidden">Toggle menu</span>
          <div class="navicon"></div>
        </button>
        <ul class="hidden-links hidden"></ul>
      </nav>
    </div>
  </div>
</div>


    <div class="initial-content">
      



<div id="main" role="main">
  

  <div class="archive">
    
      <h1 id="page-title" class="page__title">tutorial</h1>
    
    ## Introduction

We're going to build an example application that mirrors the `golang` [cosmos-sdk](https://github.com/cosmos/cosmos-sdk) example application called [Nameservice](https://github.com/cosmos/sdk-tutorials/tree/master/nameservice). There is also a tutorial for that application which you can find [here](https://tutorials.cosmos.network/nameservice/tutorial/00-intro.html) for comparison.

## Contents
1. [Introduction](README.md)
    - [Application Specification](README.md#application-specification)
    - [How to Read this Tutorial](README.md#how-to-read-this-tutorial)
    - [Tutorial Goals](README.md#tutorial-goals)
2. Foundations
    - [Overview](Foundations/Overview.md)
    - [BaseApp](Foundations/BaseApp.md)
    - [Modules](Foundations/Modules.md)
        1. [Definition](Foundations/Modules.md#definition)
        2. [Composition](Foundations/Modules.md#composition)
3. Nameservice
    - [Overview](Tutorial/Nameservice/Overview.md)
    - [Types](Tutorial/Nameservice/Types.md)
        1. [Using A Typed Key Value Store](Tutorial/Nameservice/Types.md#using-a-typed-key-value-store)
        2. [Tutorial.Nameservice.Types](Tutorial/Nameservice/Types.md#tutorialnameservicetypes)
    - [Message](Tutorial/Nameservice/Message.md)
        1. [Message Types](Tutorial/Nameservice/Message.md#message-types)
        2. [Tutorial.Nameservice.Message](Tutorial/Nameservice/Message.md#tutorialnameservicemessage)
    - [Keeper](Tutorial/Nameservice/Keeper.md)
        1. [Definition](Tutorial/Nameservice/Keeper.md#definition)
        2. [Tutorial.Nameservice.Keeper](Tutorial/Nameservice/Keeper.md#tutorialnameservicekeeper)
    - [Query](Tutorial/Nameservice/Query.md)
        1. [Definition](Tutorial/Nameservice/Query.md#definition)
        2. [Tutorial.Nameservice.Query](Tutorial/Nameservice/Query.md#tutorialnameservicequery)
    - [Module](Tutorial/Nameservice/Module.md)
        1. [Tutorial.Nameservice.Module](Tutorial/Nameservice/Module.md#tutorialnameservicemodule)
    - [Application](Tutorial/Nameservice/Application.md)
        1. [From Modules To App](Tutorial/Nameservice/Application.md#from-modules-to-app)
        2. [Tutorial.Nameservice.Application](Tutorial/Nameservice/Application.md#tutorialnameserviceapplication)


## Application Specification
The Nameservice application is a simple marketplace for a name resolution service. Let us say that a `Name` resolves to type called `Whois` where 

```haskell
data Whois = Whois
  { whoisValue :: Text
  , whoisOwner :: Address
  , whoisPrice :: Amount
  }
```

This means that users can buy and sell entries in a shared mapping of type `Name -> Whois` where:
1. An unclaimed `Name` can be bought by a user and set to an arbitrary value.
2. Existing `(Name, Whois)` pairs can be updated by their owner or sold to a new owner for the price.
3. Existing `(Name, Whois)` pairs can be deleted by their owner and the owner receives a refund for the purchase price.

The application consists of three modules:
1. `Auth` - Manages accounts for users, things like nonces and token balances.
2. `Token` - Allows users manage their tokens, things like transfering or burning.
3. `Nameservice` - Controls the shared `Name -> Value` mapping described above.

## How to Read this Tutorial

This tutorial is largely written as a literate haskell file to simulate developing the Nameservice app from scratch. The file structure is similar to the actual app. We will partially develop a haskell module corresponding to what you find in the app, but possibly not the whole thing. Thus whenever we depend on a haskell module in the tutorial, rather than importing from the tutorial itself we will import from the app.

The benefit of this is that we don't have to develop the entire application in this tutorial. Any breaking changes in the app will (hopefully) break the tutorial and so if you can read this, the tutorial is correct.

## Tutorial Goals
The goal of this tutorial is to explain how the Nameservice app is constructed using the `hs-abci-sdk` package. Nameservice is a relatively simple but still non-trivial application.
If you would like to start with something simpler, you can view the tutorial for the [simple-storage](https://github.com/f-o-a-m/hs-abci/tree/master/hs-abci-examples/simple-storage) example application.

This tutorial should teach you:
1. How to construct application specific modules.
2. How to enable a module to receive application specific transactions. 
3. How to compose modules and wire up an application.
4. How to add event logging, console logging, and other effects to module.
4. How to use the type system to control the capabilities of a module.

The SDK makes heavy use of the effects system brought to haskell by the [polysemy](https://hackage.haskell.org/package/polysemy-1.2.3.0) library. We're not going to explain how this library works here, there are several existing tutorials that do this already. Suffice it to say that polysemy encourages the application developer to develop modules that have well defined roles and scopes, and to prohibit certain modules from interfering with the roles and scopes of other modules unless explicitly allowed by the type system. 

It is also allows the application developer to construct modules without much regard for how they will plug into the SDK, leaving that job to the SDK itself.

(This tutorial is integrated as a literate haskell file, meaning that the following is necessary to ensure it compiles.) 
```haskell
main :: IO ()
main = pure ()
```

[Next: BaseApp](Foundations/Overview.md)


<h3 class="archive__subtitle">Recent Posts</h3>






  </div>
</div>
    </div>

    

    <div id="footer" class="page__footer">
      <footer>
        <!-- start custom footer snippets -->

<!-- end custom footer snippets -->
        <div class="page__footer-follow">
  <ul class="social-icons">
    

    

    <li><a href="/hs-abci/feed.xml"><i class="fas fa-fw fa-rss-square" aria-hidden="true"></i> Feed</a></li>
  </ul>
</div>

<div class="page__footer-copyright">&copy; 2020 . Powered by <a href="https://jekyllrb.com" rel="nofollow">Jekyll</a> &amp; <a href="https://mademistakes.com/work/minimal-mistakes-jekyll-theme/" rel="nofollow">Minimal Mistakes</a>.</div>

      </footer>
    </div>

    
  <script src="/hs-abci/assets/js/main.min.js"></script>
  <script src="https://kit.fontawesome.com/4eee35f757.js"></script>










  </body>
</html>
