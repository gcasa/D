//
//  MicroInstruction.m
//  D
//
//  Created by Gregory Casamento on 8/24/20.
//  Copyright © 2020 Open Logic Corporation. All rights reserved.
//

#import "MicroInstruction.h"

/// Decodes a single microcode word.
/// </summary>
@implementation MicroInstruction

- (instancetype) initWithMicroInstruction: (unsigned long)word
{
    self = [super init];
    
    if (self == nil)
    {
        return nil;
    }
    
    rA =                (int)((word & 0xf00000000000) >> 44);
    rB =                (int)((word & 0x0f0000000000) >> 40);
    aS =      (AluSourcePair)((word & 0x00e000000000) >> 37);
    aF =        (AluFunction)((word & 0x001c00000000) >> 34);
    aD =                (int)((word & 0x000300000000) >> 32);
    ep =                      (word & 0x000080000000) != 0;
    Cin =                     (word & 0x000040000000) != 0;
    enSU =                    (word & 0x000020000000) != 0;
    mem =                     (word & 0x000010000000) != 0;
    fSfY = (FunctionSelectFY)((word & 0x00000c000000) >> 26);
    fSfZ = (FunctionSelectFZ)((word & 0x000003000000) >> 24);
    fX =          (XFunction)((word & 0x000000f00000) >> 20);
    fY =                (int)((word & 0x0000000f0000) >> 16);
    fZ =                (int)((word & 0x00000000f000) >> 12);
    INIA =              (int)((word & 0x000000000fff));


    //
    // Instruction metadata that can be precomputed and cached
    //
    Cycle = (fX == cycle) ||
            (fSfY == fyNorm && ((YNormFunction)fY) == cycle);
    Shift =
        ((fX == shift) ||
         Cycle);

    AluNeedsXBus = (aS == D0 || aS == DA || aS == DQ);

    AluDestination = aD | (Shift ? 0x4 : 0x0);

    SURead = enSU && !Cin;

    SUWrite = enSU && Cin;

    LoadMap = fX == LoadMap ||
         (fSfY == fyNorm &&
          (YNormFunction)fY == YNormFunction.LoadMap);

    ABypass = AluDestination == 0x2;

    LoadStackP = (fSfY == FunctionSelectFY.fyNorm &&
                 (YNormFunction)fY == YNormFunction.LoadstackP);

    LoadIBPtr1 = (fSfZ == fzNorm && ((ZNormFunction)fZ) == LoadIBPtr1);

    AlwaysIBDisp = (fSfY == FunctionSelectFY.fyNorm &&
                    (YNormFunction)fY == YNormFunction.IBDisp) &&
                    LoadIBPtr1;

    LoadIB = fSfY == FunctionSelectFY.fyNorm &&
              (YNormFunction)fY == YNormFunction.LoadIB;

    UAddress = (rA << 4) | fZ;

    switch (fX)
    {
        case XFunction.pCallRet0:
        case XFunction.pCallRet1:
        case XFunction.pCallRet2:
        case XFunction.pCallRet3:
        case XFunction.pCallRet4:
        case XFunction.pCallRet5:
        case XFunction.pCallRet6:
        case XFunction.pCallRet7:
            LinkAddress = (int)fX;
            break;

        default:
            LinkAddress = -1;
            break;
    }

    MarMapMDR = mem || LoadMap;

    LateLRotN = !ABypass && fSfZ == fzNorm;

    if (fSfY == FunctionSelectFY.Byte)
    {
        // Byte constant
        Byte = (byte)((fY << 4) | fZ);
    }
    else if (fSfZ == Nibble)
    {
        // Nibble constant
        Byte = (byte)fZ;
    }
    else
    {
        // No constant value.
        Byte = 0;
    }

    BOOL fxPop = (fX == XFunction.pop);
    BOOL fzPop = (fSfZ == fzNorm && ((ZNormFunction)fZ) == pop);

    Pop = fxPop || fzPop;

    //
    // There is a special case if both fxPop and fzPop are specified: stackP is still decremented by 1,
    // but a trap is invoked if stackP is 1 or 0 (rather than just 0).
    //
    DoublePop = fxPop && fzPop;
           
    Push = (fX == XFunction.push) ||
           (fSfY == FunctionSelectFY.fyNorm && ((YNormFunction)fY) == YNormFunction.push) ||
           (fSfZ == fzNorm && ((ZNormFunction)fZ) == push);

    StackOperation = Pop || Push;

    //
    // From the HWref (p. 33):
    // "Multiple pop's and push's can be specified per microinstruction in order to ameliorate the detection
    //  of Stack overflow or underflow.  For instance, fXpop (i.e. the pop in the fX field), fZpop, and
    //  push executed together leave the stackPointer unmodified, yet simulate two pop's with respect to
    //  stack underflow detection..."
    // The actual overflow detection logic is controlled by a PROM, there's nothing too weird going on
    // here (other than overloading to provide only semi-related semantics, which is annoying.)  At
    // any rate, we precompute the check that's being requested (if any) so we don't have to do it
    // at execution time.
    // TODO: might make sense to dump the PROM and use that.
    //
    if (fxPop && fzPop && Push)
    {
        StackTest = StackTestType.Underflow2;
    }
    else if (Push && fzPop)
    {
        StackTest = StackTestType.Overflow;
    }
    else if (fxPop && Push)
    {
        StackTest = StackTestType.Underflow;
    }
    else
    {
        // No non-modify test, just normal stack behavior.
        StackTest = StackTestType.None;
    }
    
    return self;
}

- (NSString *) ToString()
{
    return [NSString stringWithFormat: @"rA=%0x rB=%0x aS=%ld aD=%ld ep=%ld Cin=%ld enSU=%ld mem=%ld fSY=%ld fSZ=%ld fX=%ld fY=%ld fZ=%0x INIA=%0x"
            // String.Format("rA={0:x} rB={1:x} aS={2} aF={3} aD={4} ep={5} Cin={6} enSU={7} mem={8} fSY={9} fSZ={10} fX={11} fY={12:x} fZ={13:x} INIA={14:x3}",
        rA, rB, aS, aF, aD, ep, Cin, enSU, mem, fSfY, fSfZ, fX, fY, fZ, INIA);
}

- (NSStrung *) Disassemble: (int) cycle
{
    //
    // Build ALU op, start with the sources:
    //

    string aluR;
    string aluS;
    BOOL Rzero = false;
    BOOL Szero = false;

    string xBusValue = DisassembleXBusSource(cycle);

    switch (aS)
    {
        case AluSourcePair.AB:
            aluR = String.Format("R{0:x}", rA);
            aluS = String.Format("R{0:x}", rB);
            break;

        case AluSourcePair.AQ:
            aluR = String.Format("R{0:x}", rA);
            aluS = "Q";
            break;

        case AluSourcePair.ZA:
            aluR = "0";
            Rzero = true;
            aluS = String.Format("R{0:x}", rA);
            break;

        case AluSourcePair.ZB:
            aluR = "0";
            Rzero = true;
            aluS = String.Format("R{0:x}", rB);
            break;

        case AluSourcePair.ZQ:
            aluR = "0";
            Rzero = true;
            aluS = "Q";
            break;

        case AluSourcePair.D0:
            aluR = xBusValue;
            aluS = "0";
            Szero = true;
            break;

        case AluSourcePair.DA:
            aluR = xBusValue;
            aluS = String.Format("R{0:x}", rA);
            break;

        case AluSourcePair.DQ:
            aluR = xBusValue;
            aluS = "Q";
            break;

        default:
            throw new InvalidOperationException("Unexpected ALU source pair.");
    }

    //
    // Select operation
    //
    string aluOp;
    switch (aF)
    {
        case AluFunction.RplusS:
            if (Rzero)
            {
                aluOp = aluS;
            }
            else if (Szero)
            {
                aluOp = aluR;
            }
            else
            {
                aluOp = String.Format("{0}+{1}", aluR, aluS);
            }
            break;

        case AluFunction.SminusR:
            if (Rzero)
            {
                aluOp = aluS;
            }
            else if (Szero)
            {
                aluOp = "-" + aluR;
            }
            else
            {
                aluOp = String.Format("{0}-{1}", aluS, aluR);
            }
            break;

        case AluFunction.RminusS:
            if (Rzero)
            {
                aluOp = "-" + aluS;
            }
            else if (Szero)
            {
                aluOp = aluR;
            }
            else
            {
                aluOp = String.Format("{0}-{1}", aluR, aluS);
            }
            break;

        case AluFunction.RorS:
            if (Rzero)
            {
                aluOp = aluS;
            }
            else if (Szero)
            {
                aluOp = aluR;
            }
            else
            {
                aluOp = String.Format("{0} or {1}", aluR, aluS);
            }
            break;

        case AluFunction.RandS:
            if (Rzero)
            {
                aluOp = "0";
            }
            else if (Szero)
            {
                aluOp = "0";
            }
            else
            {
                aluOp = String.Format("{0} and {1}", aluR, aluS);
            }
            break;

        case AluFunction.notRandS:
            if (Rzero)
            {
                aluOp = aluS;
            }
            else if (Szero)
            {
                aluOp = "0";
            }
            else
            {
                aluOp = String.Format("~{0} and {1}", aluR, aluS);
            }
            break;

        case AluFunction.RxorS:
            if (Rzero)
            {
                aluOp = aluS;
            }
            else if (Szero)
            {
                aluOp = aluR;
            }
            else
            {
                aluOp = String.Format("{0} xor {1}", aluR, aluS);
            }
            break;

        case AluFunction.notRxorS:
            if (Szero)
            {
                aluOp = "~" + aluR;
            }
            else
            {
                aluOp = String.Format("~{0} xor {1}", aluR, aluS);
            }
            break;

        default:
            throw new InvalidOperationException("Unexpected ALU operation");
    }

    //
    // Select register writeback (to rB)
    // Q writeback, and Y source (F, or A bypass)
    //
    int writeFn = aD | (Shift ? 0x4 : 0x0);
    string regAssignment;
    BOOL aBypass = false;
    BOOL yBusIsSourceForDestination = false;
    BOOL aluNoWriteBack = false;
    switch(writeFn)
    {
        case 0:
            // no write, Q<-F
            regAssignment = String.Format("Q<- {0}{1}", aluOp, GetCarryMod());
            yBusIsSourceForDestination = true;
            break;

        case 1:
            // no write.
            regAssignment = String.Format("{0}{1}", aluOp, GetCarryMod());
            yBusIsSourceForDestination = false;
            aluNoWriteBack = true;
            break;

        case 2:
            // R[rB] <- F, no write to Q, A Bypass for YBus<-
            regAssignment = String.Format("R{0:x}<- {1}{2}", rB, aluOp, GetCarryMod());
            aBypass = true;
            yBusIsSourceForDestination = true;
            break;

        case 3:
            // R[rB] <- F, no write to Q
            regAssignment = String.Format("R{0:x}<- {1}{2}", rB, aluOp, GetCarryMod());
            yBusIsSourceForDestination = true;
            break;

        case 4:
            if (Cycle)
            {
                // double-word right shift
                regAssignment = String.Format("R{0:x}<- DRShift1 {1}{2}{3}", rB, aluOp, GetCarryMod(), Cin ? " SE<-1" : String.Empty);
            }
            else
            {
                // double-word arithmetic right shift.
                regAssignment = String.Format("R{0:x}<- DARShift1 {1}{2}{3}", rB, aluOp, GetCarryMod(), Cin ? " SE<-1" : String.Empty);
            }
            yBusIsSourceForDestination = true;
            break;

        case 5:
            if (Cycle)
            {
                // F: single-word right rotate:
                regAssignment = String.Format("R{0:x}<- RRot1 {1}{2}", rB, aluOp, GetCarryMod());
            }
            else
            {
                // F: single-word right shift w/carryIn to MSB:
                regAssignment = String.Format("R{0:x}<- RShift1 {1}{2}{3}", rB, aluOp, GetCarryMod(), Cin ? " SE<-1" : String.Empty);
            }
            yBusIsSourceForDestination = true;
            break;

        case 6:
            if (Cycle)
            {
                // double-word left shift
                regAssignment = String.Format("R{0:x}<- DLShift1 {1}{2}{3}", rB, aluOp, GetCarryMod(), Cin ? " SE<-1" : String.Empty);
            }
            else
            {
                // double-word arithmetic left shift
                regAssignment = String.Format("R{0:x}<- DALShift1 {1}{2}{3}", rB, aluOp, GetCarryMod(), Cin ? " SE<-1" : String.Empty);
            }
            yBusIsSourceForDestination = true;
            break;

        case 7:
            if (Cycle)
            {
                // single-word left rotate:
                regAssignment = String.Format("R{0:x}<- LRot1 {1}{2}", rB, aluOp, GetCarryMod());
            }
            else
            {
                // single-word left shift w/carryIn to MSB:
                regAssignment = String.Format("R{0:x}<- LShift1 {1}{2}{3}", rB, aluOp, GetCarryMod(), Cin ? " SE<-1" : String.Empty);
            }
            yBusIsSourceForDestination = true;
            break;

        default:
            throw new InvalidOperationException("Unexpected sh,,aD value.");
    }

    string yBusValue = aBypass ? String.Format("R{0:x}, {1}", rA, regAssignment) : String.Format("{0}", regAssignment);

    string fxFunc = String.Empty;
    BOOL xBusIsSourceForDestination = false;

    BOOL yBusBranch = false;
    BOOL xBusBranch = false;

    // Handle fX functions that aren't implicitly handled elsewhere (shift, cycle)
    switch (fX)
    {
        case XFunction.pCallRet0:
        case XFunction.pCallRet1:
        case XFunction.pCallRet2:
        case XFunction.pCallRet3:
        case XFunction.pCallRet4:
        case XFunction.pCallRet5:
        case XFunction.pCallRet6:
        case XFunction.pCallRet7:
            fxFunc = String.Format("pCall/Ret{0} ", (int)fX);
            break;

        case XFunction.LoadRH:
            fxFunc = String.Format("RH{0:x}<-", rB);
            xBusIsSourceForDestination = true;
            break;

        case XFunction.LoadCinFrompc16:
            fxFunc = "SE<-pc16 ";
            break;

        case XFunction.LoadMap:
            fxFunc = String.Format("Map<- RH{0:x},,", rB);
            yBusIsSourceForDestination = true;
            break;

        case XFunction.pop:
            fxFunc = "pop ";
            break;

        case XFunction.push:
            fxFunc = "push ";
            break;
    }

    string fyFunc = String.Empty;

    // Handle fY functions that aren't implicitly handled elsewhere (cycle, Byte, etc.)
    switch (fSfY)
    {
        case FunctionSelectFY.fyNorm:
            switch ((YNormFunction)fY)
            {
                case YNormFunction.ExitKern:
                    fyFunc = "ExitKern ";
                    break;

                case YNormFunction.EnterKern:
                    fyFunc = "EnterKern ";
                    break;

                case YNormFunction.ClrIntErr:
                    fyFunc = "ClrIntErr ";
                    break;

                case YNormFunction.IBDisp:
                    fyFunc = "IBDisp ";
                    break;

                case YNormFunction.MesaIntRq:
                    fyFunc = "MesaIntRq ";
                    break;

                case YNormFunction.LoadstackP:
                    fyFunc = "stackP<-";
                    yBusIsSourceForDestination = true;
                    break;

                case YNormFunction.LoadIB:
                    fyFunc = "IB<-";
                    xBusIsSourceForDestination = true;
                    break;

                case YNormFunction.LoadMap:
                    fyFunc = String.Format("Map<- RH{0:x},,", rB);
                    break;

                case YNormFunction.Refresh:
                    fyFunc = "Refresh ";
                    break;

                case YNormFunction.push:
                    fyFunc = "push ";
                    break;

                case YNormFunction.ClrDPRq:
                    fyFunc = "ClrDPRq ";
                    break;

                case YNormFunction.ClrIOPRq:
                    fyFunc = "ClrIOPRq ";
                    break;

                case YNormFunction.ClrRefRq:
                    fyFunc = "ClrRefRq ";
                    break;

                case YNormFunction.ClrKFlags:
                    fyFunc = "ClrKFlags ";
                    break;
            }
            break;

        case FunctionSelectFY.DispBr:
            fyFunc = ((YDispBrFunction)fY).ToString() + " ";

            switch ((YDispBrFunction)fY)
            {
                case YDispBrFunction.NegBr:
                case YDispBrFunction.ZeroBr:
                case YDispBrFunction.NibCarryBr:
                case YDispBrFunction.PgCarryBr:
                case YDispBrFunction.CarryBr:
                case YDispBrFunction.PgCrOvDisp:
                case YDispBrFunction.YDisp:
                case YDispBrFunction.YIODisp:
                    yBusBranch = true;
                    break;

                case YDispBrFunction.XRefBr:
                case YDispBrFunction.XwdDisp:
                case YDispBrFunction.XHDisp:
                case YDispBrFunction.XLDisp:
                case YDispBrFunction.XDisp:
                case YDispBrFunction.XC2npcDisp:
                    xBusBranch = true;
                    break;
            }

            break;

        case FunctionSelectFY.IOOut:
            if (fY != 0xb && fY != 0xe)
            {
                YIOOutFunction yIOOut = ((YIOOutFunction)fY);
                fyFunc = yIOOut.ToString() + "<-";

                // IOOut functions are roughly split between taking data from the XBus or the YBus.
                xBusIsSourceForDestination =
                    (yIOOut == YIOOutFunction.IOPOData ||
                     yIOOut == YIOOutFunction.IOPCtl ||
                     yIOOut == YIOOutFunction.KOData ||
                     yIOOut == YIOOutFunction.KCtl ||
                     yIOOut == YIOOutFunction.EOData ||
                     yIOOut == YIOOutFunction.EICtl ||
                     yIOOut == YIOOutFunction.DCtl ||
                     yIOOut == YIOOutFunction.PCtl ||
                     yIOOut == YIOOutFunction.EOCtl ||
                     yIOOut == YIOOutFunction.KCmd ||
                     yIOOut == YIOOutFunction.POData
                    );

                yBusIsSourceForDestination = (!xBusIsSourceForDestination && (fY != 0xb && fY != 0xe));
                
            }
            break;
    }

    string fzFunc = String.Empty;

    // Handle fZ functions that aren't implicitly handled elsewhere (IOXIn)
    switch (fSfZ)
    {
        case fzNorm:
            switch((ZNormFunction)fZ)
            {
                case Refresh:
                    fzFunc = "Refresh ";
                    break;

                case LoadIBPtr1:
                    fzFunc = "IBPtr<-1 ";
                    break;

                case LoadIBPtr0:
                    fzFunc = "IBPtr<-0 ";
                    break;

                case LoadCinFrompc16:
                    fzFunc = "SE<-pc16 ";
                    break;

                case pop:
                    fzFunc = "pop ";
                    break;

                case push:
                    fzFunc = "push ";
                    break;

                case AltUaddr:
                    fzFunc = "AltUaddr ";
                    break;

                case LRot0:
                    fzFunc = "LRot0 ";
                    break;

                case LRot12:
                    fzFunc = "LRot12 ";
                    break;

                case LRot8:
                    fzFunc = "LRot8 ";
                    break;

                case LRot4:
                    fzFunc = "LRot4 ";
                    break;
            }
            break;
    }

    // SU reg write
    string suWriteStr = String.Empty;
    BOOL suWrite = enSU && Cin;
    BOOL suRead = enSU && !Cin;
    if (suWrite)
    {
        switch((int)fSfZ)
        {
            case 0:
            case 1:
                suWriteStr = "STK<-";
                break;

            case 2:
            case 3:
                suWriteStr = String.Format("U{0:x2}<-", (rA << 4) | fZ);
                break;
        }

        yBusIsSourceForDestination = true;
    }

    if(!yBusIsSourceForDestination && !xBusIsSourceForDestination)
    {
        suWriteStr = "Xbus<- ";

        // Y bus is implicitly used to provide an X bus value if nothing else is selected.
        yBusIsSourceForDestination = string.IsNullOrEmpty(xBusValue);
    }

    // MAR or MDR writes:
    string memWrite = String.Empty;

    if (mem)
    {
        if (cycle == 1)
        {
            memWrite = "MAR<- ";
        }
        else if (cycle == 2)
        {
            memWrite = "MDR<- ";
        }
        else if (cycle == -1)
        {
            memWrite = "{MAR/MDR/MD} ";
        }
    }

    //
    // The below is kind of messy because of conflation of the ALU with the Y-Bus way up above, etc.
    // Bear with me.
    //

    //
    // The Y Bus value is important and needs to be included in the disassembly if one or more of the
    // below are true:
    //  - A register assignment is taking place
    //  - The Y Bus is being used as a data source
    //  - A dispatch or branch involving the Y Bus or ALU is being invoked during this instruction.
    //
    BOOL showyBusValue = (yBusBranch || yBusIsSourceForDestination || !aluNoWriteBack);

    //
    // The X Bus value is important and needs to be included in the disassembly if one or more of the
    // below are true:
    //  - The ALU isn't already using the X Bus as an input
    //  - The X Bus is being used as a data source
    //  - A dispatch or branch involving the X Bus is being invoked during this instruction.
    //
    BOOL showxBusValue = (xBusBranch || !AluNeedsXBus || xBusIsSourceForDestination);

    string disassembly = String.Format("{0}{1}{2}{3}{4}{5}{6} [{7:x3}]",
        fxFunc,
        fyFunc,
        fzFunc,
        memWrite,
        suWriteStr,
        showxBusValue ? xBusValue : String.Empty,
        showyBusValue ? yBusValue : String.Empty,
        INIA);


    return disassembly;
}

private string GetCarryMod()
{
    string mod = String.Empty;
    BOOL add = (aF == AluFunction.RplusS);
    BOOL sub = (aF == AluFunction.RminusS || aF == AluFunction.SminusR);

    if (Cin & add)
    {
        mod = "+1";
    }
    else if (!Cin & sub)
    {
        mod = "-1";
    }

    return mod;
}

private string DisassembleXBusSource(int cycle)
{
    string xBus = String.Empty;

    // Byte and/or Nibble.  In theory these are mutually exclusive,
    // but there's nothing that prevents them both from being coded at the same time.
    // If this happens, Byte takes precedence.
    if (fSfY == FunctionSelectFY.Byte)
    {
        xBus = String.Format("byte({0:x2})", ((fY << 4) | fZ));
    }

    if(fSfZ == Nibble && fSfY != FunctionSelectFY.Byte)
    {
        xBus = String.Format("nibble({0:x1})", fZ);
    }
    else if (fSfZ == IOXIn)
    {
        // IOXIn sources
        switch((ZIOXIn)fZ)
        {
            case ZIOXIn.ReadEIdata:
                xBus += "EIData";
                break;

            case ZIOXIn.ReadEStatus:
                xBus += "EStatus";
                break;

            case ZIOXIn.ReadKIData:
                xBus += "KIData";
                break;

            case ZIOXIn.ReadKStatus:
                xBus += "KStatus";
                break;

            case ZIOXIn.ReadMStatus:
                xBus += "MStatus";
                break;

            case ZIOXIn.ReadKTest:
                xBus += "KTest";
                break;

            case ZIOXIn.ReadIOPIData:
                xBus += "IOPIData";
                break;

            case ZIOXIn.ReadIOPStatus:
                xBus += "IOPStatus";
                break;

            case ZIOXIn.ReadErrnIBnStkp:
                xBus += "ErrnIBnStkP";
                break;

            case ZIOXIn.ReadRH:
                xBus += String.Format("RH{0:x}", rB);
                break;

            case ZIOXIn.ReadibNA:
                xBus += "ibNA";
                break;

            case ZIOXIn.ReadibLow:
                xBus += "ibLow";
                break;

            case ZIOXIn.ReadibHigh:
                xBus += "ibHigh";
                break;

            default:
                xBus += ((ZIOXIn)fZ).ToString();
                break;
        }
    }

    if (enSU && !Cin)   // Cin is 0 for reads
    {
        // SU read operations
        switch((int)fSfZ)
        {
            case 0:
            case 1:
                xBus += "STK";
                break;

            case 2:
            case 3:
                xBus += String.Format("U{0:x2}", (rA << 4) | fZ);
                break;
        }
    }

    if (mem && cycle == 3)
    {
        xBus += "<-MD";
    }

    return xBus;
}

@end
