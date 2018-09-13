header_type ethernet_t {
    fields {
        dst_addr        : 48; // width in bits
        src_addr        : 48;
        ethertype       : 16;
    }
}

header_type ipv4_t {
    fields {
        version : 4;
        ihl : 4;
        diffserv : 8;
        totalLen : 16;
        identification : 16;
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr: 32;
    }
}

header_type routing_metadata_t {
    fields {
        tcpLength : 16;
    }
}

metadata routing_metadata_t routing_metadata;


header_type udp_t {
    fields {
        sourcePort : 16;
        destPort : 16;
        length_ : 16;
        checksum : 16;
    }
}

header_type tcp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        seqNo : 32;
        ackNo : 32;
        dataOffset : 4;
        res : 4;
        flags : 8;
        //ecn : 2;
        //ctrl : 6;
        window : 16;
        checksum : 16;
        urgentPtr : 16;
    }
}
header_type tcp_opt_t {
    fields {
		a : 32;
        b : 32;
        c : 32;
	}
}

header_type queue_delay_t {
	fields {
		delay : 32;
	}
}

