//
//  AM2901.m
//  D
//
//  Created by Gregory Casamento on 8/24/20.
//  Copyright © 2020 Open Logic Corporation. All rights reserved.
//

#import "AM2901.h"

@implementation AM2901

- (instancetype) init
{
    self = [super init];
    if (self != nil)
    {
        [[self class] buildTables];
    }
    return self;
}

- (ushort*) R
{
    return _r;
}

- (ushort) Q
{
    return _q;
}

- (void) execute: (MicroInstruction *)i
       ALUdinput: (ushort)d
         carryIn: (BOOL)carryIn
         loadMAR: (BOOL)loadMAR
{
    
}

- (void) executeAccurate: (MicroInstruction *)i
               ALUdinput: (ushort)d
                 carryIn: (BOOL)carryIn
                 loadMAR: (BOOL)loadMAR  // cycle accurate execute...
{
    
}

+ (BOOL) calcOverflow: (int)r :(int)s :(int)cIn
{
    int p0 = (r | s) & 0x1;
    int p1 = ((r | s) & 0x2) >> 1;
    int p2 = ((r | s) & 0x4) >> 2;
    int p3 = ((r | s) & 0x8) >> 3;

    int g0 = (r & s & 0x1);
    int g1 = (r & s & 0x2) >> 1;
    int g2 = (r & s & 0x4) >> 2;
    int g3 = (r & s & 0x8) >> 3;

    int c4 = g3 | (p3 & g2) | (p3 & p2 & g1) | (p3 & p2 & p1 & g0) | (p3 & p2 & p1 & p0 & cIn);
    int c3 = g2 | (p2 & g1) | (p2 & p1 & g0) | (p2 & p1 & p0 & cIn);

    return (c3 ^ c4) != 0;
}

+ (BOOL) calcCarryAritmetic: (int)r :(int)s :(int)cIn
{
    int p0 = (r | s) & 0x1;
    int p1 = ((r | s) & 0x2) >> 1;
    int p2 = ((r | s) & 0x4) >> 2;
    int p3 = ((r | s) & 0x8) >> 3;

    int g0 = (r & s & 0x1);
    int g1 = (r & s & 0x2) >> 1;
    int g2 = (r & s & 0x4) >> 2;
    int g3 = (r & s & 0x8) >> 3;

    int c4 = g3 | (p3 & g2) | (p3 & p2 & g1) | (p3 & p2 & p1 & g0) | (p3 & p2 & p1 & p0 & cIn);

    return c4 != 0;
}

+ (BOOL) calcCarryOr: (int)r :(int)s :(int)cIn
{
    int p0 = (r | s) & 0x1;
    int p1 = ((r | s) & 0x2) >> 1;
    int p2 = ((r | s) & 0x4) >> 2;
    int p3 = ((r | s) & 0x8) >> 3;

    int c4 = (~(p3 & p2 & p1 & p0) & 0x1) | cIn;

    return c4 != 0;
}

+ (BOOL) calcCarryAnd: (int)r :(int)s :(int)cIn
{
    int g0 = (r & s & 0x1);
    int g1 = (r & s & 0x2) >> 1;
    int g2 = (r & s & 0x4) >> 2;
    int g3 = (r & s & 0x8) >> 3;

    int c4 = g3 | g2 | g1 | g0 | cIn;

    return c4 != 0;
}

+ (BOOL) calcCarryNotXor: (int)r :(int)s :(int)cIn
{
    int p0 = (r | s) & 0x1;
    int p1 = ((r | s) & 0x2) >> 1;
    int p2 = ((r | s) & 0x4) >> 2;
    int p3 = ((r | s) & 0x8) >> 3;

    int g0 = (r & s & 0x1);
    int g1 = (r & s & 0x2) >> 1;
    int g2 = (r & s & 0x4) >> 2;
    int g3 = (r & s & 0x8) >> 3;

    int c4 = ~(g3 | (p3 & g2) | (p3 & p2 & g1) | (p3 & p2 & p1 & p0 & (g0 | ~cIn))) & 0x1;

    return c4 != 0;
}

+ (BOOL) calcOverflowNotXor: (int)r :(int)s :(int)cIn
{
    int p0 = (r | s) & 0x1;
     int p1 = ((r | s) & 0x2) >> 1;
     int p2 = ((r | s) & 0x4) >> 2;
     int p3 = ((r | s) & 0x8) >> 3;

     int g0 = (r & s & 0x1);
     int g1 = (r & s & 0x2) >> 1;
     int g2 = (r & s & 0x4) >> 2;
     int g3 = (r & s & 0x8) >> 3;

     int ovr = ((~p2 | (~g2 & ~p1) | (~g2 & ~g1 & ~p0) | (~g2 & ~g1 & ~g0 & cIn)) ^
         (~p3 | (~g3 & ~p2) | (~g3 & ~g2 & ~p1) | (~g3 & ~g2 & ~g1 & ~p0) | (~g3 & ~g2 & ~g1 & ~g0 & cIn))) & 0x1;

     return ovr != 0;
}

+ (void) buildTables
{
    for (int r = 0; r < 16; r++)
    {
        for (int s = 0; s < 16; s++)
        {
            for (int c = 0; c < 2; c++)
            {
                _overflowTable[r][ s][ c] = [self calcOverflow:r :s :c];
                _carryTableArithmetic[r][ s][ c] = [self calcCarryAritmetic:r :s :c];
                _carryTableOr[r][ s][ c] = [self calcCarryOr:r :s :c];
                _carryTableAnd[r][ s][ c] = [self calcCarryAnd:r :s :c];
                _carryTableNotXor[r][ s][ c] = [self calcCarryNotXor:r :s :c];
                _overflowNotXor[r][ s][ c] = [self calcOverflowNotXor: r :s :c];
            }
        }
    }
}

@end
