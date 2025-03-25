#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import logging
import subprocess
from subprocess import CalledProcessError, CompletedProcess, TimeoutExpired
from typing import List, Optional

# Configure logger
logging.basicConfig(
    level=logging.DEBUG,
    format="%(message)s",
)
logger = logging.getLogger(__name__)


EMPTY_MESSAGE_RETURN = "(empty)"


def spawn_process(
    command: List[str], timeout: Optional[int] = None
) -> Optional[CompletedProcess]:
    """
    This function spawns a subprocess using the provided command and captures its output. If the command
    exits with a non-zero status or exceeds the specified timeout, an error is logged and the function
    returns None.

    Args:
        command (List[str]): A list of strings representing the command and its arguments to execute.
        timeout (Optional[int]): The maximum time in seconds to wait for the command to complete.
                                 If None, no timeout is applied. Defaults to None.

    Returns:
        Optional[CompletedProcess]: The CompletedProcess object if the command executes successfully;
                                    otherwise, None is returned.
    """
    try:
        result: CompletedProcess = subprocess.run(
            command,
            capture_output=True,
            text=True,
            check=True,  # Raises CalledProcessError on non-zero exit
            timeout=timeout,
        )
        return result

    except CalledProcessError as e:
        error_msg = (
            f"Command failed with exit code: {e.returncode}\n"
            f"Command: {' '.join(e.cmd)}\n"
            f"Output: {e.stdout.strip() if e.stdout else EMPTY_MESSAGE_RETURN}\n"
            f"Error: {e.stderr.strip() if e.stderr else EMPTY_MESSAGE_RETURN}"
        )
        logger.error(error_msg)

    except TimeoutExpired as e:
        error_msg = (
            f"Command timed out.\n"
            f"Command: {' '.join(e.cmd)}\n"
            f"Timeout Duration: {e.timeout} seconds"
        )
        logger.error(error_msg)

    return None


def automate() -> None:
    """ """
    try:
        result: Optional[CompletedProcess] = spawn_process(
            command=["ip", "-c", "-h", "-s", "addr"]
        )
        if isinstance(result, CompletedProcess):
            logger.info("Process output:\n%s", result.stdout)

    except Exception as e:
        logger.exception("Unexpected exception: %s", e, exc_info=False)


if __name__ == "__main__":
    automate()
