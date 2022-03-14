//
//  MicroInstruction.h
//  D
//
//  Created by Gregory Casamento on 8/24/20.
//  Copyright © 2020 Open Logic Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

enum AluSourcePair
{
 AQ = 0,
 AB = 1,
 ZQ = 2,
 ZB = 3,
 ZA = 4,
 DA = 5,
 DQ = 6,
 D0 = 7,
};
typedef NSUInteger AluSourcePair;

enum
{
 RplusS      = 0,
 SminusR     = 1,
 RminusS     = 2,
 RorS        = 3,
 RandS       = 4,
 notRandS    = 5,
 RxorS       = 6,
 notRxorS    = 7,
};
typedef NSUInteger AluFunction;

enum
{
 DispBr = 0,
 fyNorm = 1,
 IOOut  = 2,
 FSByte   = 3,
};
typedef NSUInteger FunctionSelectFY;

enum
{
 fzNorm = 0,
 Nibble = 1,
 Uaddr  = 2,
 IOXIn  = 3,
};
typedef NSUInteger FunctionSelectFZ;

enum
{
 pCallRet0   = 0x0,
 pCallRet1   = 0x1,
 pCallRet2   = 0x2,
 pCallRet3   = 0x3,
 pCallRet4   = 0x4,
 pCallRet5   = 0x5,
 pCallRet6   = 0x6,
 pCallRet7   = 0x7,
 Noop        = 0x8,
 LoadRH      = 0x9,
 shift       = 0xa,
 cycle       = 0xb,
 LoadCinFrompc16 = 0xc,
 LoadMap     = 0xd,
 pop         = 0xe,
 push        = 0xf,
};
typedef NSUInteger XFunction;

enum YNormFunction
{
 ExitKern    = 0x0,
 EnterKern   = 0x1,
 ClrIntErr   = 0x2,
 IBDisp      = 0x3,
 MesaIntRq   = 0x4,
 LoadstackP  = 0x5,
 LoadIB      = 0x6,
 acycle       = 0x7,
 aNoop        = 0x8,
 aLoadMap     = 0x9,
 aRefresh     = 0xa,
 apush        = 0xb,
 ClrDPRq     = 0xc,
 ClrIOPRq    = 0xd,
 ClrRefRq    = 0xe,
 ClrKFlags   = 0xf,
};
typedef NSUInteger YNormFunction;

enum
{
 NegBr       = 0x0,
 ZeroBr      = 0x1,
 NZeroBr     = 0x2,
 MesaIntBr   = 0x3,
 PgCarryBr   = 0x4,
 CarryBr     = 0x5,
 XRefBr      = 0x6,
 NibCarryBr  = 0x7,
 XDisp       = 0x8,
 YDisp       = 0x9,
 XC2npcDisp  = 0xa,
 YIODisp     = 0xb,
 XwdDisp     = 0xc,
 XHDisp      = 0xd,
 XLDisp      = 0xe,          // AKA XDirtyDisp
 PgCrOvDisp  = 0xf,
};
typedef NSUInteger YDispBrFunction;

enum
{
 IOPOData    = 0x0,
 IOPCtl      = 0x1,
 KOData      = 0x2,
 KCtl        = 0x3,
 EOData      = 0x4,
 EICtl       = 0x5,
 DCtlFifo    = 0x6,
 DCtl        = 0x7,
 DBorder     = 0x8,
 PCtl        = 0x9,
 MCtl        = 0xa,
 Invalid0    = 0xb,
 EOCtl       = 0xc,
 KCmd        = 0xd,
 Invalid1    = 0xe,
 POData      = 0xf,
};
typedef NSUInteger YIOOutFunction;

enum
{
 Refresh     = 0x0,
 LoadIBPtr1  = 0x1,
 LoadIBPtr0  = 0x2,
 zLoadCinFrompc16 = 0x3,
 LoadBank    = 0x4,
 zpop         = 0x5,
 zpush        = 0x6,
 AltUaddr    = 0x7,
 Noop0       = 0x8,
 Noop1       = 0x9,
 Noop2       = 0xa,
 Noop3       = 0xb,
 LRot0       = 0xc,
 LRot12      = 0xd,
 LRot8       = 0xe,
 LRot4       = 0xf
};
typedef NSUInteger ZNormFunction;

// For Zap Rowsdower
enum
{
 ReadEIdata  = 0x0,
 ReadEStatus = 0x1,
 ReadKIData  = 0x2,
 ReadKStatus = 0x3,
 KStrobe     = 0x4,
 ReadMStatus = 0x5,
 ReadKTest   = 0x6,
 EStrobe     = 0x7,
 ReadIOPIData = 0x8,
 ReadIOPStatus = 0x9,
 ReadErrnIBnStkp = 0xa,
 ReadRH      = 0xb,
 ReadibNA    = 0xc,
 Readib      = 0xd,
 ReadibLow   = 0xe,
 ReadibHigh  = 0xf,
};
typedef NSUInteger ZIOXIn;

enum
{
 None,
 Underflow,
 Overflow,
 Underflow2,
};
typedef NSUInteger StackTestType;

 /// <summary>

@interface MicroInstruction : NSObject
{
    /// <summary>
    /// 2901 A reg addr, U addr [0-3]
    /// </summary>
     int rA;

    /// <summary>
    /// 2901 B reg addr, RH addr
    /// </summary>
     int rB;

    /// <summary>
    /// 2901 alu Source operand pair
    /// </summary>
     AluSourcePair aS;

    /// <summary>
    /// 2901 alu Function
    /// </summary>
     AluFunction aF;

    /// <summary>
    /// 2901 alu Destination/shift control
    /// </summary>
     int aD;

    /// <summary>
    /// Even Parity
    /// </summary>
     BOOL ep;

    /// <summary>
    /// 2901 Carry In, Shift Ends, writeSU (if enSU = 1)
    /// </summary>
     BOOL Cin;

    /// <summary>
    /// enable SU reg file
    /// </summary>
     BOOL enSU;

    /// <summary>
    /// MAR<- (if c1), MDR<- (if c2), <-MD (if c3)
    /// </summary>
     BOOL mem;

    /// <summary>
    /// Function field selector for Y
    /// </summary>
     FunctionSelectFY fSfY;

    /// <summary>
    /// Function field selector for Z
    /// </summary>
     FunctionSelectFZ fSfZ;

    /// <summary>
    /// X Function
    /// </summary>
     XFunction fX;

    /// <summary>
    /// Y Function
    /// </summary>
     int fY;

    /// <summary>
    /// Z Function
    /// </summary>
     int fZ;

    /// <summary>
    /// Next Instruction Address
    /// </summary>
     int INIA;

    //
    // The following are metadata for this instruction, used to speed execution.
    //

    /// <summary>
    /// Instruction specifies a Cycle of ALU output when writing back to R/Q
    /// </summary>
     BOOL Cycle;

    /// <summary>
    /// Instruction specifies a Shift of ALU as above.
    /// </summary>
     BOOL Shift;

    /// <summary>
    /// Instruction requires XBus input to ALU.
    /// </summary>
     BOOL AluNeedsXBus;

    /// <summary>
    /// Destination control for the ALU
    /// </summary>
     int AluDestination;

    /// <summary>
    /// Instruction specifies an SU register read
    /// </summary>
     BOOL SURead;

    /// <summary>
    /// Instruction specifies an SU register write
    /// </summary>
     BOOL SUWrite;

    /// <summary>
    /// Instruction specifies a Map<- operation.
    /// </summary>
     BOOL LoadMap;

    /// <summary>
    /// Instruction uses the A-bypass mode for the ALU.
    /// </summary>
     BOOL ABypass;

    /// <summary>
    /// Instruction specifies a stackP<- operation.
    /// </summary>
     BOOL LoadStackP;

    /// <summary>
    /// Instruction specifies a push operation
    /// </summary>
     BOOL Push;

    /// <summary>
    /// Instruction specifies a pop operation
    /// </summary>
     BOOL Pop;

    /// <summary>
    /// Instruction specifies a double-pop operation.
    /// </summary>
     BOOL DoublePop;

    /// <summary>
    /// Whether any stack operations (pushes or pops) occur in this instruction.
    /// </summary>
     BOOL StackOperation;

    /// <summary>
    /// Specifies the kind of test specified by the various
    /// push/pop instruction fields.
    /// </summary>
     StackTestType StackTest;

    /// <summary>
    /// Causes an IBDisp branch even if IB is not full;
    /// specified by IBDisp + IBPtr<-1
    /// </summary>
     BOOL AlwaysIBDisp;

    /// <summary>
    /// Whether an IB<- is specified this instruction.
    /// </summary>
     BOOL LoadIB;

    /// <summary>
    /// Whether the instruction specifies an ibPtr<-1 operation,
    /// which can be used to modify other operations.
    /// </summary>
     BOOL LoadIBPtr1;

    /// <summary>
    /// Constant address used to address U register when loading/storing
    /// </summary>
     int UAddress;

    /// <summary>
    /// Constant byte value
    /// </summary>
    /// <returns></returns>
     unsigned char aByte;

    /// <summary>
    /// Link address specified by instruction (or -1 if not specified)
    /// </summary>
     int LinkAddress;

    /// <summary>
    /// Whether the instruction specifies an MAR<-, Map<-, or MDR<- operation.
    /// </summary>
     BOOL MarMapMDR;

    /// <summary>
    /// Whether to do an LrotN operation after the ALU runs.
    /// </summary>
     BOOL LateLRotN;
}
@end

NS_ASSUME_NONNULL_END
