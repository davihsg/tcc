from typing import Optional, List


class Alert(object):
    def __init__(
        self,
        id: str,
        spiffe_id: Optional[str],
        monitor_name: str,
        severity: int,
        period_start: str,
        period_end: str,
        state: str,
        global_scope: bool,
    ):
        self.id = id
        self.spiffe_id = spiffe_id
        self.monitor_name = monitor_name
        self.severity = severity
        self.period_start = period_start
        self.period_end = period_end
        self.state = state
        self.global_scope = global_scope


class PostAlertRequestBody:
    def __init__(self, alerts: List[Optional[Alert]]):
        self.alerts = [Alert(**alert) for alert in alerts if alert is not None]


ACTIVE = "ACTIVE"
COMPLETED = "COMPLETED"
