# Switch from Let's Encrypt Staging to Production Environment

Let's Encrypt provides a [staging platform](https://letsencrypt.org/docs/staging-environment/) to test against and this is the environment the package will request certificates from.
Once you have [verified the staging certificates](https://www.cyberciti.biz/faq/test-ssl-certificates-diagnosis-ssl-certificate/) have been issued correctly, the user must switch to requesting certificates from Let's Encrypt's production environment to receive trusted certificates.

The package automatically installs a cluster issuer for both the staging and production environments is `cluster-issuer.yaml`, switching the issuers involves switching the `cert-manager` [annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/) in `config.yaml`.

In `config.yaml`, you will find the following code block:

```yaml
ingress:
  enabled: true
  annotations:
    kubernetes.io/tls-acme: "true"
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: "letsencrypt-staging"
    https:
      enabled: true
      type: nginx
  host:
    - <host-name>
  tls:
    - secretName: <secret-name>
      hosts:
        - <host-name>
```

:rotating_light: This code block will actually appear twice in `config.yaml`.
Once for the `binder` ingress, and again for the `hub` ingress. :rotating_light:

Update the `cert-manager.io/cluster-issuer` annotation from `letsencrypt-staging` to `letsencrypt-prod`.

:rotating_light: Remember to perform this change in **both** places where the annotation appears! :rotating_light:

Now upgrade your cluster using [`upgrade.sh`](../upgrade.sh) or the `helm` command:

```bash
helm upgrade BINDERHUB_NAME jupyterhub/binderhub \
  --version=BINDERHUB_VERSION \
  -f /path/to/secret.yaml \
  -f /path/to/config.yaml \
  --wait
```

Congratulations, you should now be issued trusted certificates from the Let's Encrypt production environment!
