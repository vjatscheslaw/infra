# DNS-over-TLS secure channel

## Idea

The idea behind such a configuration of DNS-over-TLS between two nodes, that are controlled by you, is to secure you from anyone meddling into your DNS querying results on a route from your home office to your VDS.

Going further, from your VDS, to the actual DNS server (Cloudflare, Quad9, etc.), your DNS traffic gets secured with the vendor's keys (Cloudflare's DNS server private key, for example).

## Precautions

Beware, that DNS-over-TLS does not encrypt IP addresses, returned to you in response. This is why I advise you to set IP-address of your SSH tunnel interface on your home office Internet gateway machine's Unbound instance, as a single address for DNS forwarding.

## Usage

In this folder, you may find two examples of unbound.conf files, for the inner home gateway, as well as for your VDS (OUTER). I believe, the _initVDS_ and _initPI_ scripts use their own copies, so these may need to go in the future. Left here for reference.
