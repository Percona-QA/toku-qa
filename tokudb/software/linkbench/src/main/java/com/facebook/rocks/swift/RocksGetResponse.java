package com.facebook.rocks.swift;

import com.facebook.swift.codec.*;
import java.util.*;

import static com.google.common.base.Objects.toStringHelper;

@ThriftStruct("RocksGetResponse")
public class RocksGetResponse
{
    @ThriftConstructor
    public RocksGetResponse(
        @ThriftField(value=1, name="retCode") final RetCode retCode,
        @ThriftField(value=2, name="value") final byte [] value
    ) {
        this.retCode = retCode;
        this.value = value;
    }

    private final RetCode retCode;

    @ThriftField(value=1, name="retCode")
    public RetCode getRetCode() { return retCode; }

    private final byte [] value;

    @ThriftField(value=2, name="value")
    public byte [] getValue() { return value; }

    @Override
    public String toString()
    {
        return toStringHelper(this)
            .add("retCode", retCode)
            .add("value", value)
            .toString();
    }
}
