#define _GNU_SOURCE
#include <dlfcn.h>
#include <netdb.h>
#include <stddef.h>

typedef int (*getaddrinfo_fn)(const char *, const char *,
                             const struct addrinfo *, struct addrinfo **);

int getaddrinfo(const char *node, const char *service,
                const struct addrinfo *hints, struct addrinfo **result) {
    static getaddrinfo_fn real_getaddrinfo;
    struct addrinfo ipv4_hints;

    if (real_getaddrinfo == NULL) {
        real_getaddrinfo = (getaddrinfo_fn)dlsym(RTLD_NEXT, "getaddrinfo");
    }
    if (hints == NULL) {
        ipv4_hints = (struct addrinfo){0};
        ipv4_hints.ai_family = AF_INET;
        return real_getaddrinfo(node, service, &ipv4_hints, result);
    }
    ipv4_hints = *hints;
    if (ipv4_hints.ai_family == AF_UNSPEC) {
        ipv4_hints.ai_family = AF_INET;
    }
    return real_getaddrinfo(node, service, &ipv4_hints, result);
}
