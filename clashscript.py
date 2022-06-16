rule = [
        ['iprules', 'rules-utun-ip', 'REJECT'],
        ['dstip','127.0.0.1','REJECT'],
        ['keywordrules',  ['epochtimes','dafahao','falundata','falundafa'], 'REJECT'],
        ['domainrules', 'rules-game', 'Game'],
        ['ipnoresolverules', 'rules-netflix-ip', 'Netflix'],
        ['port', 27010, 'Game'],
        ['geoip','CN','DIRECT'],
        ['processname','curl','Proxy']
        ['ports', [27010, 27080, 'udp', '!cn'], 'Game']
]
def domainrules(domainrule, proxy, ctx, metadata):
    src_ip = metadata["src_ip"]
    dst_port = metadata["dst_port"]
    network = metadata["network"]
    if ctx.rule_providers[domainrule].match(metadata):
        return proxy
    return "none"

def keywordrules(keywords, proxy, ctx, metadata):
    host = metadata["host"]
    dst_port = metadata["dst_port"]
    network = metadata["network"]
    src_ip = metadata["src_ip"]
    for key in keywords:
        if key in host:
            return proxy
    return "none"

def ipnoresolverules(ipnoresolverules, proxy, ctx, metadata):
    dst_ip = metadata['dst_ip']
    dst_port = metadata["dst_port"]
    network = metadata["network"]
    host = metadata["host"]
    src_ip = metadata["src_ip"]
    if (dst_ip != "" and host == "") or (dst_ip == host):
        if ctx.rule_providers[ipnoresolverules].match(metadata):
            return proxy
    return "none"

def iprules(iprules, proxy, ctx, metadata):
    host = metadata["host"]
    src_ip = metadata["src_ip"]
    dst_port = metadata["dst_port"]
    network = metadata["network"]
    if host == "":
        if ctx.rule_providers[iprules].match(metadata):
            return proxy
        return "none"
    dst_ip = ctx.resolve_ip(host)
    tmp_ip = metadata['dst_ip']
    if dst_ip == "":
        return "none"
    metadata['dst_ip'] = dst_ip
    if ctx.rule_providers[iprules].match(metadata):
        return proxy
    if tmp_ip != "" and dst_ip != tmp_ip:
        metadata['dst_ip'] = tmp_ip
    return "none"

def geoip(geoip, proxy, ctx, metadata):
    src_ip = metadata["src_ip"]
    host = metadata["host"]
    dst_port = metadata["dst_port"]
    network = metadata["network"]
    if host == "":
        if ctx.rule_providers[iprules].match(metadata):
            return proxy
        return "none"
    dst_ip = ctx.resolve_ip(host)
    tmp_ip = metadata['dst_ip']
    if dst_ip == "":
        return "none"
    metadata['dst_ip'] = dst_ip
    code = ctx.geoip(dst_ip)
    if code == geoip:
        return proxy
    if tmp_ip != "" and dst_ip != tmp_ip:
        metadata['dst_ip'] = tmp_ip
    return "none"

def processname(names, proxy, ctx, metadata):
    process_name = ctx.resolve_process_name(metadata)
    src_ip = metadata["src_ip"]
    dst_port = metadata["dst_port"]
    network = metadata["network"]
    for name in names:
        if name == process_name:
            return proxy
    return "none"

def port(port, proxy, ctx, metadata):
    dst_port = metadata["dst_port"]
    network = metadata["network"]
    if int(dst_port) == port:
        return proxy
    return "none"

def ports(ports, proxy, ctx, metadata):
    dst_port = metadata["dst_port"]
    network = metadata["network"]
    
    if ports[0] >= ports[1]:
        ctx.log('[Script] ERROR Ports Rule !!! Please check the rule!!!!!')
        proxy_ = 'DIRECT'
    if ports[0] <= int(dst_port) and int(dst_port) <= ports[1]:
        if len(ports) == 4:
            if "default" == ports[3] and ( network == ports[2] or ports[2] == "all" ):
                return proxy
            elif "cn" in ports[3] and "!" not in ports[3]:
                if ctx.rule_providers['rules-cn-ip'].match(metadata) and ( network == ports[2] or ports[2] == "all" ):
                    return proxy
                return "none"
            elif "cn" in ports[3] and "!" in ports[3]:
                if not ctx.rule_providers['rules-cn-ip'].match(metadata) and ( network == ports[2] or ports[2] == "all" ):
                    return proxy
                return "none"
        elif len(ports) == 3 and ( network == ports[2] or ports[2] == "all" ):
            return proxy
    return "none"

def dstip(ip, proxy, ctx, metadata):
    dst_ip = metadata["dst_ip"]
    host = metadata["host"]
    dst_port = metadata["dst_port"]
    network = metadata["network"]

    if dst_ip == "":
        dst_ip = ctx.resolve_ip(host)
    if dst_ip == ip:
        return proxy
    return "none"


def matchrule(ruletype, rules, proxy, ctx, metadata):
    if ruletype == 'domainrules':
        proxy_ = domainrules(rules, proxy, ctx, metadata)
    elif ruletype == 'keywordrules':
        proxy_ = keywordrules(rules, proxy, ctx, metadata)
    elif ruletype == 'ipnoresolverules':
        proxy_ = ipnoresolverules(rules, proxy, ctx, metadata)
    elif ruletype == 'iprules':
        proxy_ = iprules(rules, proxy, ctx, metadata)
    elif ruletype == 'geoip':
        proxy_ = geoip(rules, proxy, ctx, metadata)
    elif ruletype == 'processname':
        proxy_ = processname(rules, proxy, ctx, metadata)
    elif ruletype == 'port':
        proxy_ = port(rules, proxy, ctx, metadata)
    elif ruletype == 'ports':
        proxy_ = ports(rules, proxy, ctx, metadata)
    elif ruletype == 'dstip':
        proxy_ = dstip(rules, proxy, ctx, metadata)
    else:
        ctx.log('[Script] ERROR!!! Please check the rule!!!!!')
        proxy_ = 'DIRECT'

    return proxy_
    
    
def main(ctx, metadata):
    host = metadata["host"]
    src_ip = metadata["src_ip"]
    dst_ip = metadata["dst_ip"]
    dst_port = metadata["dst_port"]
    src_port = metadata["src_port"]
    network = metadata["network"]

    for key in rule:
        proxy = matchrule(key[0], key[1], key[2], ctx, metadata)
        # print(proxy)
        if proxy != "none":
            return proxy

    return Final
