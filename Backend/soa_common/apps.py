import logging
import os
import sys
import threading
import time

from django.apps import AppConfig
from django.conf import settings

logger = logging.getLogger(__name__)


def _should_register():
    """Chỉ tự đăng ký khi service thực sự đang chạy (runserver), không chạy khi test hay migrate."""
    if not getattr(settings, 'SERVICE_AUTO_REGISTER', False):
        return False
    if 'runserver' not in sys.argv:
        return False
    # runserver có autoreload chạy 2 tiến trình; chỉ tiến trình con (RUN_MAIN=true) mới phục vụ request
    return os.environ.get('RUN_MAIN') == 'true' or '--noreload' in sys.argv


def _heartbeat_loop():
    from soa_common.registry_client import register_self

    registered = False
    while True:
        try:
            register_self()
            if not registered:
                logger.warning('[%s] registered with service registry', settings.SERVICE_NAME)
                registered = True
        except Exception as error:  # noqa: BLE001 - registry có thể chưa bật, thử lại ở vòng sau
            registered = False
            logger.warning('[%s] cannot reach service registry: %s', settings.SERVICE_NAME, error)
        time.sleep(settings.SERVICE_HEARTBEAT_SECONDS)


class SoaCommonConfig(AppConfig):
    name = 'soa_common'

    def ready(self):
        if _should_register():
            threading.Thread(target=_heartbeat_loop, name='registry-heartbeat', daemon=True).start()
