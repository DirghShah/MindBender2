import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

/// Best-effort lookup of the host's primary LAN IPv4 address. Used to print
/// a copy-pasteable URL at proxy startup so the teacher can punch it into the
/// iPads without digging through System Settings.
enum LANIP {
    static func firstIPv4() -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let cur = ptr {
            defer { ptr = cur.pointee.ifa_next }

            guard let addr = cur.pointee.ifa_addr else { continue }
            let flags = Int32(cur.pointee.ifa_flags)
            let family = addr.pointee.sa_family

            // Up, running, not loopback, IPv4.
            guard (flags & (IFF_UP | IFF_RUNNING)) != 0,
                  (flags & IFF_LOOPBACK) == 0,
                  family == UInt8(AF_INET) else { continue }

            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            #if canImport(Darwin)
            let len = socklen_t(addr.pointee.sa_len)
            #else
            let len = socklen_t(MemoryLayout<sockaddr_in>.size)
            #endif
            if getnameinfo(addr, len, &host, socklen_t(host.count),
                           nil, 0, NI_NUMERICHOST) == 0 {
                let ip = String(cString: host)
                // Skip link-local addresses (169.254.x.x) — they exist when
                // no DHCP server has assigned a usable address yet.
                if !ip.hasPrefix("169.254.") {
                    return ip
                }
            }
        }
        return nil
    }
}
