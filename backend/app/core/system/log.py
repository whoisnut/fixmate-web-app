# Log usage examples:
# logger.info(f'ClassName.FunctionName: Message {variable}')

import logging
import asyncio
import os
import sys
import threading
import traceback
from datetime import datetime

from app.core.enum import LOG_ERROR_LEVEL_ENUM

# Create the logs directory if it doesn't exist
log_directory = "logs"
os.makedirs(log_directory, exist_ok=True)

today_str = datetime.now().strftime("%Y-%m-%d")
log_file_path = os.path.join(log_directory, "app.log")

handler = logging.FileHandler(
    filename=log_file_path,
    mode='a',
    encoding='utf-8',
    delay=True
)

# Log Format
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
handler.setFormatter(formatter)


class RootOnlyFilter(logging.Filter):
    def filter(self, record: logging.LogRecord) -> bool:
        return record.name == "root"


handler.addFilter(RootOnlyFilter())
logging.basicConfig(
    level=logging.INFO,
    handlers=[handler]
)


def _run_async_safely(coro):
    """Run async function safely, handling both async and sync contexts."""
    try:
        asyncio.get_running_loop
        asyncio.create_task(coro)
    except RuntimeError:
        threading.Thread(target=asyncio.run, args=(coro,)).start()


async def send_error(level: str, msg: str) -> None:
    """Send error to external monitoring system (placeholder)."""
    try:
        # TODO: Implement error sending to external monitoring
        # This is a placeholder for sending errors to Telegram, Slack, etc.
        pass
    except Exception as e:
        logging.warning(f'sendError {e}')


class Logger:
    """Custom logger with color support and error levels."""

    class StyleModifier:
        BLUE = '\033[94m'
        GREEN = '\033[92m'
        RED = '\033[91m'
        YELLOW = '\033[93m'
        TEXT_BOLD = '\033[1m'
        TEXT_UNDERLINE = '\033[4m'
        ENDC = '\033[0m'

    class Error:
        """Error logger with different severity levels."""

        def __init__(self, logger_instance):
            self.logger_instance = logger_instance

        def __log(self, *args, include_traceback: bool = True) -> str:
            st = ''
            for arg in args:
                st = st + ' ' + str(arg)

            # Automatically include traceback if we're in an exception context
            if include_traceback and sys.exc_info()[0] is not None:
                error_traceback = traceback.format_exc()
                st = f'{st} traceback: {error_traceback}'

            logging.error(f'{Logger.StyleModifier.RED}{st}{Logger.StyleModifier.ENDC}')
            return st

        def __call__(self, *args) -> None:
            self.__log(*args)

        def low(self, *args) -> None:
            st = self.__log(*args)
            _run_async_safely(send_error(level=LOG_ERROR_LEVEL_ENUM.LOW, msg=st))

        def medium(self, *args) -> None:
            st = self.__log(*args)
            _run_async_safely(send_error(level=LOG_ERROR_LEVEL_ENUM.MEDIUM, msg=st))

        def high(self, *args) -> None:
            st = self.__log(*args)
            _run_async_safely(send_error(level=LOG_ERROR_LEVEL_ENUM.HIGH, msg=st))

        def critical(self, *args) -> None:
            st = self.__log(*args)
            _run_async_safely(send_error(level=LOG_ERROR_LEVEL_ENUM.CRITICAL, msg=st))

    def __init__(self):
        self.error = Logger.Error(self)

    @staticmethod
    def info(*args) -> None:
        st = ''
        for arg in args:
            st = st + ' ' + str(arg)
        logging.info(f'{Logger.StyleModifier.BLUE}{st}{Logger.StyleModifier.ENDC}')

    @staticmethod
    def warn(*args) -> None:
        st = ''
        for arg in args:
            st = st + ' ' + str(arg)
        logging.warning(f'{Logger.StyleModifier.YELLOW}{st}{Logger.StyleModifier.ENDC}')

    @staticmethod
    def track(*args) -> None:
        st = ''
        for arg in args:
            st = st + ' ' + str(arg)
        logging.info(f'{Logger.StyleModifier.GREEN}{st}{Logger.StyleModifier.ENDC}')


logger = Logger()
