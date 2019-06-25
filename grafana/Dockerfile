FROM grafana/grafana

USER root
# Next line is to fix slim docker image
# From https://github.com/debuerreotype/debuerreotype/issues/10#issuecomment-450480318
RUN for i in $(seq 1 8); do mkdir -p "/usr/share/man/man${i}"; done
# Instal psql
RUN apt-get update && apt-get install -y postgresql-client
USER grafana

COPY ./run-with-postgres.bash /run-with-postgres.bash
COPY ./dev-provisioning/datasources/ /etc/grafana/provisioning/datasources/
COPY ./dev-provisioning/dashboards/ /etc/grafana/provisioning/dashboards/
COPY ./dashboards/ /var/lib/grafana/dashboards/

ENTRYPOINT ["/run-with-postgres.bash"]
