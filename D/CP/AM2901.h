//
//  AM2901.h
//  D
//
//  Created by Gregory Casamento on 8/24/20.
//  Copyright © 2020 Open Logic Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MicroInstruction;

// tables...
BOOL _overflowTable[16][16][2];
BOOL _carryTableArithmetic[16][16][2];
BOOL _carryTableOr[16][16][2];
BOOL _carryTableAnd[16][16][2];
BOOL _carryTableNotXor[16][16][2];
BOOL _overflowNotXor[16][16][2];

@interface AM2901 : NSObject
{
    // registers...
    ushort _r[16];
    ushort _q;
    
    // flags...
    BOOL _zero;
    BOOL _neg;
    BOOL _nibCarry;
    BOOL _pgCarry;
    BOOL _carryOut;
    BOOL _overflow;
    
    // output
    ushort y;
}

- (ushort*) R;
- (ushort) Q;

- (void) execute: (MicroInstruction *)i
       ALUdinput: (ushort)d
         carryIn: (BOOL)carryIn
         loadMAR: (BOOL)loadMAR;

- (void) executeAccurate: (MicroInstruction *)i
               ALUdinput: (ushort)d
                 carryIn: (BOOL)carryIn
                 loadMAR: (BOOL)loadMAR;  // cycle accurate execute...

+ (BOOL) calcOverflow: (int)r :(int)s :(int)cIn;
+ (BOOL) calcCarryAritmetic: (int)r :(int)s :(int)cIn;
+ (BOOL) calcCarryOr: (int)r :(int)s :(int)cIn;
+ (BOOL) calcCarryAnd: (int)r :(int)s :(int)cIn;
+ (BOOL) calcCarryNotXor: (int)r :(int)s :(int)cIn;
+ (BOOL) calcOverflowNotXor: (int)r :(int)s :(int)cIn;

+ (void) buildTables;

@end

NS_ASSUME_NONNULL_END
