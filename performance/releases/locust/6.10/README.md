I decided to forgo the low-user count locust tests and just re-run the 250 users test repeatedly. The results appear to further confirm the flakiness of our tests; the fluctuations of the results between runs under seemingly identical conditions, for the same release is too significant; and not easy to immediately explain.

But between 3 different runs for each version, 6.10/p7 appears to be clearly slower.

