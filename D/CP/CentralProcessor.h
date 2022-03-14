//
//  CentralProcessor.h
//  D
//
//  Created by Gregory Casamento on 8/24/20.
//  Copyright © 2020 Open Logic Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
// which task are we doing...
enum {
    Emulator = 0,
    Display,
    Ethernet,
    Refresh,
    Disk,
    IOP,
    IOPcs,
    Kernel
};
typedef NSUInteger TaskType;

// What was clicked...
enum {
    Ethernet0 = 0,
    DiskC,
    Ethernet1,
    DisplayC
};
typedef NSUInteger ClickType;

enum {
    Full = 2,
    Word = 3,
    AByte = 1,
    Empty = 0
};
typedef NSUInteger IBState;

enum {
    Normal,
    IBDispatch,
    IBRefillTrap
};
typedef NSUInteger NiaModiferType;

enum {
    ControlStoreParity = 0,
    EmulatorMemoryError = 1,
    StackOverUnderflow = 2,
    IBEmpty = 3,
};
typedef NSUInteger ErrorTrap;

enum // PortReadRegister
{
    CPDataIn = 0xeb,
    CPStatus = 0xec,
    CPCS0 = 0xf8,
    CPCS1 = 0xf9,
    CPCS2 = 0xfa,
    CPCS3 = 0xfb,
    CPCS4 = 0xfc,
    CPCS5 = 0xfd,
    CPCS6 = 0xfe,
    CPCS7 = 0xff,
};
typedef NSUInteger PortReadRegister;

enum // PortWriteRegister
{
    CPDataOut = 0xeb,
    CPControl = 0xec,
    CPClrDmaComplete = 0xee,
    CPCSa = 0xf8,
    CPCSb = 0xf9,
    CPCSc = 0xfa,
    CPCSd = 0xfb,
    CPCSe = 0xfc,
    CPCSf = 0xfd,
    TPCHigh = 0xfe,
    TPCLow = 0xff,
};
typedef NSUInteger PortWriteRegister;

// From the IOP schematic:
//  - 00 = Disabled(no wakeups)
//  - 01 = Input(wakeup when Input from IOP is available)
//  - 10 = Output(wakeup when IOP is ready for data from CP)
//  - 11 = Always wake up
enum
{
    Disabled = 0,
    Input,
    Output,
    Always,
};
typedef NSUInteger IOPTaskWakeMode;

@class DSystem;
@class MicroInstruction;
@class AM2901;

// Dandelion central processor....
@interface CentralProcessor : NSObject
{

    // Task/Temporary Program Counters
   int _tpc[8];

    // Task/Temporary Condition bits (NIA modifiers).  This is only 4 bits.
    int _tc[8];

    // Task wakeups
    BOOL _wakeup[8];

    // Current task
    TaskType _currentTask;

    // Microcode store
    unsigned long _microcode[4096];

    // Microcode decode cache
    MicroInstruction *_microcodeCache[4096];

    // 2901 ALU
    AM2901 *_alu;

    // RH registers, 8 bit
    unsigned char _rh[16];

    // Link registers, 4 bit
    // NOTE: Link register:
    // See section 2.5.4 of the HW ref;
    // Link is addressed by fX and is written with the low nibble of NIAX when
    // fX is in 0..7 and NIA[7] = 0;
    // A Link register is or'd into the low nibble of INIA when fX is in 0..7 and
    // NIA[7] = 1.  If the preceding uinstruction does not specify a branch/dispatch,
    // the Link register is loaded with a constant.
    // However if the prior instruction does specify branch/dispatch, the value loaded
    // depends on the outcome of the branch or dispatch.
    int _link[8];

    // U registers
    ushort _u[256];

    // Instruction buffer (IB)
    unsigned char _ibFront;
    unsigned char _ib[2];
    IBState _ibPtr;
    BOOL _ibEmptyCancel;

    // Table of values for next ipPtr value when decrementing ibPtr.
    IBState _nextIBPtr[4]; // = [ Empty, Empty, Word, Bite ];

    // Stack pointer, 4 bits
    int _stackP;

    // pc16 register, 1 bit
    BOOL _pc16;

    // Bus data
    ushort _xBus;
    ushort _yBus;

    // NIA modifier for branch/dispatch
    int _niaModifier;
    NiaModiferType _niaModifierType;

    // AltUAddress flag
    BOOL _altUAddr;

    //
    // Interrupt flags
    //
    BOOL _mInt;

    //
    // Error state
    //

    //
    // HWRef, section 2.5.5.2:
    // The EKErr register, read onto X[8-9] with <-ErrnIBnStkp, names the type of error:
    //   0 - control store parity error
    //   1 - Emulator memory error
    //   2 - stackPointer overflow or underflow
    //   3 - IB-Empty error
    // If, coincidentally, two or more error occur at the same time, smaller values of EKErr
    // are reported.  The error types are also accumulated until EKErr is reset: the minimum
    // value is reported when EKErr is read.
    // Cleared by ClrIntErr, which, as a side-effect, also resets any pending interrupts.
    int _eKErr;
    BOOL _emulatorErrorTrap;
    int _emulatorErrorTrapClickCount;

    /// <summary>
    /// Whether a PageCross branch occurred during the last MAR<- operation.
    /// Cleared at the beginning of the next instruction, and used to indicate whether
    /// an MDR<-, IBDisp, or AlwaysIBDisp should be canceled.
    /// </summary>
    BOOL _marPageCrossBr;

    //
    // Cycle / Click / Round data
    //
    int _cycle;                 // c1 ... c3
    ClickType _click;           // 0 ... 4

    //
    // Whether to exit the Kernel task at the end of this click
    //
    BOOL _exitKernel;

    //
    // Debugging flag: Indicates that an IBDispatch has occurred,
    // allows handling Mesa (or other bytecode) instruction breakpoints.
    //
    BOOL _ibDispatch;

    //
    // The D System we belong to
    //
    DSystem *_system;
    
    /* IO */
    //
    // Control data, IOP
    //
    BOOL _cpDmaComplete_;
    BOOL _iopWait_;      // Waiting for IOP to wake us
    BOOL _swTAddr;
    BOOL _iopAttn;
    BOOL _cpDmaMode;
    BOOL _cpDmaIn;

    //
    // Control data, CP
    //
    BOOL _wakeMode1;
    BOOL _wakeMode0;
    BOOL _cpAttn;
    BOOL _emuWake;
    IOPTaskWakeMode _wakeMode;

    //
    // Status data
    //
    BOOL _cpOutIntReq_;
    BOOL _cpInIntReq_;
    BOOL _outLatched;       // Data from CP->IOP latched
    BOOL _inLatched;        // Data from IOP->CP latched
    BOOL _iopReq;

    //
    // CP<->IOP data buffers
    //
    unsigned char _cpOutData;        // OUT from IOP (CP reads)
    unsigned char _cpInData;         // IN from CP (IOP reads)

    // Used as TPC address when IOP is writing control store or modifying TPC values.
    int _tpcAddr;

    // Temporary used when loading TPC values; stores high bits of new TPC address.
    int _tpcTemp;
}
@end

NS_ASSUME_NONNULL_END
