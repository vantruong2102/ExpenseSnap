from datetime import timedelta

from django.conf import settings
from django.db import models
from django.utils import timezone


def alive_threshold():
    return timezone.now() - timedelta(seconds=settings.SERVICE_TTL_SECONDS)


class ServiceInstanceQuerySet(models.QuerySet):
    def alive(self):
        return self.filter(last_heartbeat__gte=alive_threshold())


class ServiceInstance(models.Model):
    name = models.SlugField(max_length=64, unique=True)
    version = models.CharField(max_length=20)
    base_url = models.URLField()
    health_url = models.URLField()
    contract_url = models.URLField()
    description = models.CharField(max_length=255, blank=True)
    registered_at = models.DateTimeField(auto_now_add=True)
    last_heartbeat = models.DateTimeField(default=timezone.now)

    objects = ServiceInstanceQuerySet.as_manager()

    class Meta:
        ordering = ['name']

    def __str__(self):
        return f'{self.name} @ {self.base_url}'

    @property
    def is_alive(self):
        return self.last_heartbeat >= alive_threshold()
