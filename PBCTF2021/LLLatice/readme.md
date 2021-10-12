# LLLattice
## Prompt:

It seems like there is a UART echoserver design running on a Lattice FPGA. The UART bus runs 8N1 at a rate of 100 clocks per symbol. Can you reverse it and find out what secret it holds?

Attachment: [chal.bit](chal.bit)

Author: VoidMercy

"Hint": [This repo](https://github.com/VoidMercy/Lattice-ECP5-Bitstream-Decompiler/tree/e4659cb6fbc19c749a5f859f85fdadd19c7f9147) was updated halfway through the CTF. Prior to this update, it was not able to fully process the provided bitstream, and afterward it worked.


## Background:

This problem is very similar to Pwn2Win 2021's Ethernet From Above challenge, which also involved reversing a lattice bitstream. While I did attempt this challenge at the time, I was unable to complete it. An excelent writeup from Robert Xiao of Maple Bacon is available [here](https://ubcctf.github.io/2021/06/pwn2win-ethernetfromabove/).
That said, having attempted this challenge helped me significantly as I had some tooling already prepared. 

Also of note, I did not actually complete this challenge during the competition - I found the solution ~10 seconds after the competition ended, and had the full flag approximately 2 minutes late. 

## Process:

In solving this problem, I initially used a conglomeration of Xiao's scripts and a variety of tools and scripts I had from my attempts at solving Ethernet From Above (Vivado, prjtrellis, etc.). While I sucessfully used these tools to extract verilog, I was unable to accurately simulate the verilog, and static analysis was a non-starter.

During this time I tried using VoidMercy's Lattice decompiler, but quickly realized it wasn't compatible with the provided chal.bit, and decided this was probably a red herring. This turned out to be mostly true, until the hint was released. At this point I pivoted to a clean installation of VoidMercy's decompiler, and managed to complete the challenge in that way. The solution below starts at this point.

# Solution

1. Inspect chal.bit in a hex editor. Conveniently, the header includes the plaintext: `Part: LFE5U-25F-6CABGA381`. Now I know the specific FPGA that this challenge is using, and am able to start the decompile process.
2. Use [VoidMercy's decompiler tool](https://github.com/VoidMercy/Lattice-ECP5-Bitstream-Decompiler) to extract verilog.
3. Collapse Lattice "slice" cells to simplified RTL with yosys:
```
read_verilog chal.v
synth
flatten
opt
clean
opt_clean
write_verilog chal_opt.v
```
4. Create Vivado project with `chal_opt.v`

  The top level has just 4 io wires: 
  - `MIB_R0C60_PIOT0_JPADDIA_PIO`
    - (Input)
  - `G_HPBX0000`
    - (Input - on a clock capable pin)
  - `MIB_R0C40_PIOT0_JPADDIB_PIO`
    - (Input)
  - `MIB_R0C40_PIOT0_JTXDATA0A_SIOLOGIC`
    - (Output)

  At this point, I know from the challenge prompt that this is supposed to be some sort of 8N1 echo server, so I begin by creating a testbench to send serial data. The final version is in [top_tb.sv](top_tb.sv).  

5. The next step was to determine which IO did what. The output was pretty obvious, as was the clock pin, but at first I couldn't tell what the two input did. For this, I generated a schematic using Vivado's RTL analysis. 
![Schematic of RTL](schematic.png)
This actually provides some very useful information. For one, I can immediately differentiate the three input ports. 
  - `G_HPBX0000` (red) drives the clock pins of all of FF registers, which proves that this is indeed the clock input.
  - `MIB_R0C60_PIOT0_JPADDIA_PIO` (hot pink) drives the CLR/RST line of many (but notably not all) of the FFs, implying it is almost certainly the reset line.
  - `MIB_R0C40_PIOT0_JPADDIB_PIO` (neon green) drives two FFs in series, acting as a 2FF synchronizer. This strongly implies this is the uart data input line.

6. 
7. From here, I tried treating the remainder of the design as a semi-black box. I configured Vivado to capture the output of every single flipflop, and  Using the testbench, I tried sending various data, with 