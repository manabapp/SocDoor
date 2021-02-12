//
//  SocError.swift
//  LibSoc - Swifty POSIX Socket Library
//
//  Created by Hirose Manabu on 2021/02/12.
//

import Darwin
import Foundation

enum SocError: Error {
    case SocketError(code: errno_t, function: String)
    case ResolveError(code: Int32)
    case InvalidAddress(addr: String)
    case InvalidParameter
    case FileDeleteError
    case NotInitialized
    case InternalError
    
    var code: Int32 {
        switch self {
        case .SocketError(let code, _): return code
        case .ResolveError(let code): return code
        default: return 0
        }
    }
}

extension SocError: LocalizedError {
    var message: String {
        switch self {
        case .SocketError(_, let function): return "Error occurred in \(function)."
        case .ResolveError(_): return "Error occurred in gethostbyname."
        case .InvalidAddress(_): return "Invalid address format."
        case .InvalidParameter: return "Invalid parameter."
        case .FileDeleteError: return "Error occurred in deleting socket file."
        case .NotInitialized: return "Not initialized."
        default: return "Internal Error."
        }
    }
}

extension SocError {
    var detail: String {
        switch self {
        case .SocketError(let code, _): return "errno=\(code)[\(ERRNO_NAMES[Int(code)])]\n" + String(cString: strerror(code))
        case .ResolveError(let code): return "h_errno=\(code)\n" + String(cString: gai_strerror(code))
        case .InvalidAddress(let addr): return addr
        default: return ""
        }
    }
}

//=====================
// Global defines
//=====================
let ERRNO_NAMES: [String] = [
    "EDUMMY",           // 0: Dummy, no use
    "EPERM",            // 1: Operation not permitted
    "ENOENT",           // 2: No such file or directory
    "ESRCH",            // 3: No such process
    "EINTR",            // 4: Interrupted system call
    "EIO",              // 5: Input/output error
    "ENXIO",            // 6: Device not configured
    "E2BIG",            // 7: Argument list too long
    "ENOEXEC",          // 8: Exec format error
    "EBADF",            // 9: Bad file descriptor
    "ECHILD",           // 10: No child processes
    "EDEADLK",          // 11: Resource deadlock avoided
    "ENOMEM",           // 12: Cannot allocate memory
    "EACCES",           // 13: Permission denied
    "EFAULT",           // 14: Bad address
    "ENOTBLK",          // 15: Block device required
    "EBUSY",            // 16: Resource busy
    "EEXIST",           // 17: File exists
    "EXDEV",            // 18: Cross-device link
    "ENODEV",           // 19: Operation not supported by device
    "ENOTDIR",          // 20: Not a directory
    "EISDIR",           // 21: Is a directory
    "EINVAL",           // 22: Invalid argument
    "ENFILE",           // 23: Too many open files in system
    "EMFILE",           // 24: Too many open files
    "ENOTTY",           // 25: Inappropriate ioctl for device
    "ETXTBSY",          // 26: Text file busy
    "EFBIG",            // 27: File too large
    "ENOSPC",           // 28: No space left on device
    "ESPIPE",           // 29: Illegal seek
    "EROFS",            // 30: Read-only file system
    "EMLINK",           // 31: Too many links
    "EPIPE",            // 32: Broken pipe
    "EDOM",             // 33: Numerical argument out of domain
    "ERANGE",           // 34: Result too large
    "EAGAIN",           // 35: Resource temporarily unavailable (arias: EWOULDBLOCK - Operation would block)
    "EINPROGRESS",      // 36: Operation now in progress
    "EALREADY",         // 37: Operation already in progress
    "ENOTSOCK",         // 38: Socket operation on non-socket
    "EDESTADDRREQ",     // 39: Destination address required
    "EMSGSIZE",         // 40: Message too long
    "EPROTOTYPE",       // 41: Protocol wrong type for socket
    "ENOPROTOOPT",      // 42: Protocol not available
    "EPROTONOSUPPORT",  // 43: Protocol not supported
    "ESOCKTNOSUPPORT",  // 44: Socket type not supported
    "ENOTSUP",          // 45: Operation not supported
    "EPFNOSUPPORT",     // 46: Protocol family not supported
    "EAFNOSUPPORT",     // 47: Address family not supported by protocol family
    "EADDRINUSE",       // 48: Address already in use
    "EADDRNOTAVAIL",    // 49: Can't assign requested address
    "ENETDOWN",         // 50: Network is down
    "ENETUNREACH",      // 51: Network is unreachable
    "ENETRESET",        // 52: Network dropped connection on reset
    "ECONNABORTED",     // 53: Software caused connection abort
    "ECONNRESET",       // 54: Connection reset by peer
    "ENOBUFS",          // 55: No buffer space available
    "EISCONN",          // 56: Socket is already connected
    "ENOTCONN",         // 57: Socket is not connected
    "ESHUTDOWN",        // 58: Can't send after socket shutdown
    "ETOOMANYREFS",     // 59: Too many references: can't splice
    "ETIMEDOUT",        // 60: Operation timed out
    "ECONNREFUSED",     // 61: Connection refused
    "ELOOP",            // 62: Too many levels of symbolic links
    "ENAMETOOLONG",     // 63: File name too long
    "EHOSTDOWN",        // 64: Host is down
    "EHOSTUNREACH",     // 65: No route to host
    "ENOTEMPTY",        // 66: Directory not empty
    "EPROCLIM",         // 67: Too many processes
    "EUSERS",           // 68: Too many users
    "EDQUOT",           // 69: Disc quota exceeded
    "ESTALE",           // 70: Stale NFS file handle
    "EREMOTE",          // 71: Too many levels of remote in path
    "EBADRPC",          // 72: RPC struct is bad
    "ERPCMISMATCH",     // 73: RPC version wrong
    "EPROGUNAVAIL",     // 74: RPC prog. not avail
    "EPROGMISMATCH",    // 75: Program version wrong
    "EPROCUNAVAIL",     // 76: Bad procedure for program
    "ENOLCK",           // 77: No locks available
    "ENOSYS",           // 78: Function not implemented
    "EFTYPE",           // 79: Inappropriate file type or format
    "EAUTH",            // 80: Authentication error
    "ENEEDAUTH",        // 81: Need authenticator
    "EPWROFF",          // 82: Device power is off
    "EDEVERR",          // 83: Device error
    "EOVERFLOW",        // 84: Value too large to be stored in data type
    "EBADEXEC",         // 85: Bad executable (or shared library)
    "EBADARCH",         // 86: Bad CPU type in executable
    "ESHLIBVERS",       // 87: Shared library version mismatch
    "EBADMACHO",        // 88: Malformed Mach-o file
    "ECANCELED",        // 89: Operation canceled
    "EIDRM",            // 90: Identifier removed
    "ENOMSG",           // 91: No message of desired type
    "EILSEQ",           // 92: Illegal byte sequence
    "ENOATTR",          // 93: Attribute not found
    "EBADMSG",          // 94: Bad message
    "EMULTIHOP",        // 95: Reserved
    "ENODATA",          // 96: No message available on STREAM
    "ENOLINK",          // 97: Reserved
    "ENOSR",            // 98: No STREAM resources
    "ENOSTR",           // 99: Not a STREAM
    "EPROTO",           // 100: Protocol error
    "ETIME",            // 101: STREAM ioctl timeout
    "EOPNOTSUPP",       // 102: Operation not supported on socket
    "ENOPOLICY",        // 103: Policy not found
    "ENOTRECOVERABLE",  // 104: State not recoverable
    "EOWNERDEAD",       // 105: Previous owner died
    "EQFULL"            // 106: Interface output queue is full (arias: ELAST - Must be equal largest errno)
]
