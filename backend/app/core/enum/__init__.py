from enum import Enum


class LOG_ERROR_LEVEL_ENUM(str, Enum):
    NONE = 'NONE'
    LOW = 'LOW'
    MEDIUM = 'MEDIUM'
    HIGH = 'HIGH'
    CRITICAL = 'CRITICAL'


class ACTIVE_ENUM(str, Enum):
    YES = '1'
    NO = '0'


class STATUS_ENUM(str, Enum):
    ACTIVE = '1'
    INACTIVE = '0'


class RES_CUSTOM_CODE_ENUM(str, Enum):
    TRANSACTION_SUCCESS = '200'
    BAD_REQUEST = '400'
    AUTHENTICATED_FAILED = '401'
    INVALID_URL = '404'
    METHOD_NOT_ALLOW = '405'
    REQUEST_TIMEOUT = '408'
    UNSUPPORTED_MEDIA_TYPE = '415'

    INVALID_DATA_VALIDATION = '422'
    ALREADY_PAID = '423'
    PAID_FAIL = '424'
    PAYMENT_GATEWAY_ERROR = '425'
    TOO_MANY_REQUESTS = '429'

    INVALID_SESSION_ID = '439'
    INVALID_AMOUNT = '440'
    INTERNAL_SERVER_ERROR = '500'
    UNAVAILABLE = '503'
    GATEWAY_TIMEOUT = '504'


class RESPONSE_STATUS_ENUM(int, Enum):
    SUCCESS = 1
    FAILED = 0


class USER_ROLE_ENUM(str, Enum):
    CUSTOMER = 'customer'
    TECHNICIAN = 'technician'
    ADMIN = 'admin'


class BOOKING_STATUS_ENUM(str, Enum):
    PENDING = 'pending'
    ACCEPTED = 'accepted'
    IN_PROGRESS = 'in_progress'
    COMPLETED = 'completed'
    CANCELLED = 'cancelled'


class PAYMENT_STATUS_ENUM(str, Enum):
    PENDING = 'pending'
    PROCESSING = 'processing'
    COMPLETED = 'completed'
    FAILED = 'failed'
    REFUNDED = 'refunded'


class PAYOUT_STATUS_ENUM(str, Enum):
    PENDING = 'pending'
    APPROVED = 'approved'
    REJECTED = 'rejected'
    COMPLETED = 'completed'


class VERIFICATION_STATUS_ENUM(str, Enum):
    PENDING = 'pending'
    VERIFIED = 'verified'
    REJECTED = 'rejected'
