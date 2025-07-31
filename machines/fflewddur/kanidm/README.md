# Kanidm

## Enter a Kanidm development shell

```console
nix develop .#kanidm
```

## Logging in as IDM admin

Get IDM admin password:

```console
clan vars get fflewddur kanidm/idm-admin-password
```

Login:

```console
kanidm login --name idm_admin
```

## Add a user

First [log in as IDM admin](#logging-in-as-idm-admin).


```console
kanidm person create <username> <displayname>
kanidm person credential create-reset-token <username>
```

Set an email. It won't be used for anything, but some OAuth clients require it
(for example,
[oauth2-proxy](https://github.com/oauth2-proxy/oauth2-proxy/issues/2667)).

```console
kanidm person update <username> --mail <email>
```

## Create a group

Create a group where `idm_admin` has "entry manager rights":

```console
kanidm group create <group name> --name idm_admin
```

Add users:

```
kanidm group add-members <group name> <username>
```
