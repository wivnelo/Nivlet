#import <Foundation/Foundation.h>
#include <sys/sysctl.h>
#include <net/route.h>
#include <net/if.h>
#include <ifaddrs.h>
#include <net/if_dl.h>

int main(void) {
    @autoreleasepool {
        NSMutableDictionary *interfaces = [NSMutableDictionary dictionary];
        int mib[] = {CTL_NET, PF_ROUTE, 0, AF_UNSPEC, NET_RT_IFLIST2, 0};
        size_t size = 0;
        if (sysctl(mib, 6, NULL, &size, NULL, 0) == 0 && size > 0) {
            char *buffer = malloc(size);
            if (buffer && sysctl(mib, 6, buffer, &size, NULL, 0) == 0) {
                for (char *p = buffer; p + sizeof(struct rt_msghdr) <= buffer + size;) {
                    struct rt_msghdr *message = (struct rt_msghdr *)p;
                    if (!message->rtm_msglen || p + message->rtm_msglen > buffer + size) break;
                    if (message->rtm_type == RTM_IFINFO2 && message->rtm_msglen >= sizeof(struct if_msghdr2)) {
                        struct if_msghdr2 *info = (struct if_msghdr2 *)p;
                        char name[IF_NAMESIZE];
                        if (if_indextoname(info->ifm_index, name)) {
                            interfaces[@(name)] = [@{@"rx": @(info->ifm_data.ifi_ibytes), @"tx": @(info->ifm_data.ifi_obytes)} mutableCopy];
                        }
                    }
                    p += message->rtm_msglen;
                }
            }
            free(buffer);
        }
        struct ifaddrs *addresses = NULL;
        if (getifaddrs(&addresses) == 0) {
            for (struct ifaddrs *a = addresses; a; a = a->ifa_next) {
                if (!a->ifa_addr || a->ifa_addr->sa_family != AF_LINK) continue;
                struct sockaddr_dl *link = (struct sockaddr_dl *)a->ifa_addr;
                if (link->sdl_alen != 6) continue;
                const unsigned char *mac = (const unsigned char *)LLADDR(link);
                NSMutableDictionary *item = interfaces[@(a->ifa_name)];
                if (item) item[@"mac"] = [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x", mac[0],mac[1],mac[2],mac[3],mac[4],mac[5]];
            }
            freeifaddrs(addresses);
        }
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierChinese];
        NSDateComponents *date = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:[NSDate date]];
        NSArray *months = @[@"正月",@"二月",@"三月",@"四月",@"五月",@"六月",@"七月",@"八月",@"九月",@"十月",@"冬月",@"腊月"];
        NSArray *days = @[@"初一",@"初二",@"初三",@"初四",@"初五",@"初六",@"初七",@"初八",@"初九",@"初十",@"十一",@"十二",@"十三",@"十四",@"十五",@"十六",@"十七",@"十八",@"十九",@"二十",@"廿一",@"廿二",@"廿三",@"廿四",@"廿五",@"廿六",@"廿七",@"廿八",@"廿九",@"三十"];
        NSArray *stems = @[@"甲",@"乙",@"丙",@"丁",@"戊",@"己",@"庚",@"辛",@"壬",@"癸"];
        NSArray *branches = @[@"子",@"丑",@"寅",@"卯",@"辰",@"巳",@"午",@"未",@"申",@"酉",@"戌",@"亥"];
        NSString *lunar = @"N/A";
        if (date.month >= 1 && date.month <= 12 && date.day >= 1 && date.day <= 30 && date.year >= 1) {
            lunar = [NSString stringWithFormat:@"%@%@年 %@%@%@", stems[(date.year-1)%10], branches[(date.year-1)%12], date.isLeapMonth ? @"闰" : @"", months[date.month-1], days[date.day-1]];
        }
        NSData *data = [NSJSONSerialization dataWithJSONObject:@{@"interfaces":interfaces,@"lunar":lunar} options:0 error:NULL];
        if (!data) return 1;
        fwrite(data.bytes, 1, data.length, stdout);
    }
    return 0;
}
