import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;

/**
 * This class is used to take our assembly code and turn it into machine code
 * 
 * @author Michael Mackliet
 *
 */
public class assembler
{
	public static void main(String[] args)
	{
		assembler A = new assembler();
		A.assemble(args);
	}
	
	/**
	 * This method would just be main, except the other classes are private
	 * implementation classes, so we needed to instantiate an assembler object
	 * and have a member method that does this stuff
	 * 
	 * @param args command line args
	 */
	void assemble(String[] args)
	{
		if(args.length != 1)
		{
			System.err.println("Expected one arg, a valid file path");
			return;
		}
		
		
		InstructionSet instSet = new InstructionSet();
		ArrayList<String> program_lines = new ArrayList<String>();
		ArrayList<Integer> memory_addresses = new ArrayList<Integer>();
		String data_line = null;
		try 
		{
			FileReader fr = new FileReader(args[0]);
			BufferedReader br = new BufferedReader(fr);
			int mem_counter = 0x0000; 
			
			//This is our first pass through the file. This time around
			//we just figure out what memory addresses the labels correspond to
			//and we get rid of comments
			while((data_line = br.readLine()) != null)
			{
				//Get rid of comments
				data_line = data_line.replaceAll("\\s*#.*", "");
				if(data_line.equals(""))
				{
					continue;
				}
				if(data_line.contains("~CODE_ADDRESS"))
				{
					String address = data_line.replaceFirst("\\s*~CODE_ADDRESS\\s*=", "");
					mem_counter = Integer.decode(address.trim());
					continue;
				}
				
				if(instSet.isLabel(data_line))
				{
					String label = data_line.replaceAll("\\s|:", "");
					instSet.addLabel(label, mem_counter);
				}
				else
				{
					memory_addresses.add(mem_counter);
					program_lines.add(data_line);
					mem_counter += instSet.getSizeInstruction(data_line);
				}
				
			}
			br.close();
			fr.close();
		}
		catch(Exception e)
		{
			e.printStackTrace();
			System.err.println("Error on line: " + data_line);
			return;
		}
		
		//This is the second pass. Here we parse instructions using our instruction sets
		//And then assemble the instruction objects into machine code. We can't
		//parse or assemble something, print an error message
		try (FileOutputStream fos = new FileOutputStream("assembled.bin")) {
			ArrayList<String> coe_file = new ArrayList<String>();
			coe_file.add("memory_initialization_radix=2;\n");
			coe_file.add("memory_initialization_vector=\n\n");

			for(int i = 0; i < program_lines.size(); i++)
			{
				String machine_code = instSet.assembleInstruction(instSet.parseInstruction(program_lines.get(i)));
				if(machine_code != null)
				{
					System.out.print("0x" + Integer.toHexString(memory_addresses.get(i)) + " " + program_lines.get(i).trim());
					String[] line_parts = program_lines.get(i).split("\\s");
					for(String label : instSet.m_labels.keySet())
					{
						for(String part : line_parts)
						{
							if(part.equals(label))
							{
								System.out.print("\t(" + label + "=" + "0x" + Integer.toHexString(instSet.m_labels.get(label)) + ") ");
							}
						}
					}
					System.out.println("\n\t" + machine_code);
					
					String first_half = (machine_code.length() > 16) ? machine_code.substring(0, 16) : machine_code;
					String second_half = (machine_code.length() > 16) ? machine_code.substring(16) : "";
					String line_end = ((i == (program_lines.size()-1)) && second_half.equals("")) ? ";" : ",";
					coe_file.add(first_half + line_end + "\n");
					
					if(second_half != "")
					{
						line_end = (i == (program_lines.size()-1)) ? ";" : ",";
						coe_file.add(second_half + line_end + "\n");
					}
					
					int n_words = machine_code.length() / 16;
					for(int word_i = 0; word_i < n_words; word_i++){
						String word = machine_code.substring(word_i*16, (word_i + 1) * 16);
						
						// I know this is kind of an ugly hack... but it seems to work. 
						BigInteger code = new BigInteger(word, 2);
						
						byte[] raw_bytes = code.toByteArray();
						byte[] bytes = new byte[2];
						
						if(raw_bytes.length < 2) {
							bytes[0] = 0;
							bytes[1] = raw_bytes[0];
						}
						else if(raw_bytes.length > 2) {
							bytes[0] = raw_bytes[1];
							bytes[1] = raw_bytes[2];
						}
						else {
							bytes = raw_bytes;
						}
						
						byte[] final_bytes = new byte[2];
						
						final_bytes[0] = bytes[1];
						final_bytes[1] = bytes[0];
						
						fos.write(final_bytes);
					}
				}
				else
				{
					System.err.println("Couldn't assemble instruction: " + program_lines.get(i));
					return;
				}
			}
			writeToFile("program.coe", coe_file);
		} catch (Exception e) {
			e.printStackTrace();
		} 
		
	}
	
	private boolean writeToFile(String path, ArrayList<String> data) 
	{
		try
		{
			BufferedWriter writer = new BufferedWriter(new FileWriter(path));
			for(String line : data)
			{
				writer.write(line);
			}
			writer.close();
		}
		catch(Exception e)
		{
			e.printStackTrace();
			return false;
		}
		return true;
	}


	
	
	
	
	
	
	
	/**
	 * This enum  defines different types of arguments that an instruction can take
	 * @author Michael Mackliet
	 *
	 */
	private enum ArgType
	{
		REGISTER,
		IMMEDIATE,
		UNKNOWN;
	}
	
	/**
	 * This class creates instructions to hold parsed instruction data. 
	 * 
	 * @author Michael Mackliet
	 *
	 */
	private class Instruction
	{
		Instruction(String name, ArrayList<ArgType> argTypes, int numWordsInMemory, ArrayList<String> args, String opcode)
		{
			m_name = name;
			m_numArgs = (argTypes == null) ? 0 : argTypes.size();
			m_argTypes = (argTypes == null) ? null : new ArrayList<ArgType>(argTypes);
			m_numWordsInMemory = numWordsInMemory;
			m_args = (args == null) ? null : new ArrayList<String>(args);
			m_opcode = opcode;
		}
		public String m_name;
		public int m_numArgs;
		public ArrayList<ArgType> m_argTypes;
		public int m_numWordsInMemory;
		public ArrayList<String> m_args;
		public String m_opcode;
		
		/**
		 * This method defines equality between instructions and any object
		 */
		public boolean equals(Object other)
		{
			if(other.getClass().equals(Instruction.class))
			{
				Instruction otherInstruction = (Instruction)other;
				boolean ret_val = true;
				ret_val = ret_val && m_name.equals(otherInstruction.m_name);
				ret_val = ret_val && (m_numArgs == otherInstruction.m_numArgs);
				if(m_argTypes == null || otherInstruction.m_argTypes == null)
				{
					ret_val = ret_val && (m_argTypes == otherInstruction.m_argTypes);
				}
				else if(m_argTypes.size() != otherInstruction.m_argTypes.size())
				{
					ret_val = false;
				}
				else
				{
					for(int i = 0; i<m_argTypes.size(); i++)
					{
						ret_val = ret_val && (m_argTypes.get(i) == otherInstruction.m_argTypes.get(i));
					}
				}
				ret_val = ret_val && (m_numWordsInMemory == otherInstruction.m_numWordsInMemory);
				if(m_args == null || otherInstruction.m_args == null)
				{
					ret_val = ret_val && (m_args == otherInstruction.m_args);
				}
				else if(m_args.size() != otherInstruction.m_args.size())
				{
					ret_val = false;
				}
				else
				{
					for(int i = 0; i<m_args.size(); i++)
					{
						ret_val = ret_val && (m_args.get(i) == otherInstruction.m_args.get(i));
					}
				}
				return ret_val;
			}
			else
			{
				return false;
			}
		}
	}
	
	/**
	 * This class holds all the information for our instruction set (what instructions
	 * the set includes, their size in memory, what kinds of args they can take,
	 * what registers there are, and how to assemble everything. If you find a bug
	 * where an instruction, register, or immediate is consistently getting parsed
	 * incorrectly into machine code, this is the class to look at.
	 * @author Michael Mackliet
	 *
	 */
	private class InstructionSet
	{
		InstructionSet()
		{
			m_instructions = new HashSet<Instruction>();
			ArrayList<ArgType> argTypes = new ArrayList<ArgType>();
			argTypes.add(ArgType.REGISTER);
			argTypes.add(ArgType.REGISTER);
			m_instructions.add(new Instruction("add", argTypes, 1, null, "00000"));  // 0x00
			m_instructions.add(new Instruction("sub", argTypes, 1, null, "00001"));  // 0x01
			m_instructions.add(new Instruction("cmp", argTypes, 1, null, "00010"));  // 0x02
			m_instructions.add(new Instruction("and", argTypes, 1, null, "00011"));  // 0x03
			m_instructions.add(new Instruction("or", argTypes, 1, null, "00100"));	 // 0x04
			m_instructions.add(new Instruction("xor", argTypes, 1, null, "00101"));	 // 0x05
			m_instructions.add(new Instruction("mov", argTypes, 1, null, "00110"));  // 0x06
			m_instructions.add(new Instruction("load", argTypes, 1, null, "01001")); // 0x09
			m_instructions.add(new Instruction("store", argTypes, 1, null, "01010"));// 0x0A
			
			argTypes = new ArrayList<ArgType>();
			argTypes.add(ArgType.REGISTER);
			m_instructions.add(new Instruction("jr", argTypes, 1, null, "01011"));	 // 0x0B
			m_instructions.add(new Instruction("be", argTypes, 1, null, "01100"));	 // 0x0C
			m_instructions.add(new Instruction("bne", argTypes, 1, null, "01101"));	 // 0x0D
			m_instructions.add(new Instruction("blt", argTypes, 1, null, "00111"));  // 0x07
			m_instructions.add(new Instruction("blte", argTypes, 1, null, "01000")); // 0x08
			m_instructions.add(new Instruction("inc", argTypes, 1, null, "11111"));	 // 0x1F

			argTypes = new ArrayList<ArgType>();
			argTypes.add(ArgType.REGISTER);
			argTypes.add(ArgType.IMMEDIATE);
			m_instructions.add(new Instruction("shiftli", argTypes, 1, null, "01110")); // 0x0E
			m_instructions.add(new Instruction("shiftri", argTypes, 1, null, "01111")); // 0x0F
			
			//
			// 2 word instructions
			//
			argTypes = new ArrayList<ArgType>();
			argTypes.add(ArgType.REGISTER);
			argTypes.add(ArgType.IMMEDIATE);
			m_instructions.add(new Instruction("addi", argTypes, 2, null, "10000"));	// 0x10
			m_instructions.add(new Instruction("subi", argTypes, 2, null, "10001"));	// 0x11
			m_instructions.add(new Instruction("cmpi", argTypes, 2, null, "10010"));	// 0x12
			m_instructions.add(new Instruction("andi", argTypes, 2, null, "10011"));	// 0x13
			m_instructions.add(new Instruction("ori", argTypes, 2, null, "10100"));		// 0x14
			m_instructions.add(new Instruction("xori", argTypes, 2, null, "10101"));	// 0x15
			m_instructions.add(new Instruction("movi", argTypes, 2, null, "10110"));	// 0x16
			m_instructions.add(new Instruction("loadi", argTypes, 2, null, "10111"));	// 0x17
			m_instructions.add(new Instruction("storei", argTypes, 2, null, "11000")); // 0x18
			
			argTypes = new ArrayList<ArgType>();
			argTypes.add(ArgType.IMMEDIATE);
			m_instructions.add(new Instruction("ja", argTypes, 2, null, "11001"));
			m_instructions.add(new Instruction("bei", argTypes, 2, null, "11010"));
			m_instructions.add(new Instruction("bnei", argTypes, 2, null, "11011"));
			m_instructions.add(new Instruction("blti", argTypes, 2, null, "11100"));
			m_instructions.add(new Instruction("bltei", argTypes, 2, null, "11101"));
			m_instructions.add(new Instruction("js", argTypes, 2, null, "11110"));
			
			//Map register names to their assigned number in machine code
			m_registers = new HashMap<String, String>();
			m_registers.putIfAbsent("@0" , "0000");
			m_registers.putIfAbsent("@sp", "0001");
			m_registers.putIfAbsent("@fp", "0010");
			m_registers.putIfAbsent("@ra", "0011");
			m_registers.putIfAbsent("@a0", "0100");
			m_registers.putIfAbsent("@a1", "0101");
			m_registers.putIfAbsent("@m0", "0110");
			m_registers.putIfAbsent("@m1", "0111");
			m_registers.putIfAbsent("@rv", "1000");
			m_registers.putIfAbsent("@v0", "1001");
			m_registers.putIfAbsent("@v1", "1010");
			m_registers.putIfAbsent("@p0", "1011");
			m_registers.putIfAbsent("@p1", "1100");
			m_registers.putIfAbsent("@p2", "1101");
			m_registers.putIfAbsent("@p3", "1110");
			m_registers.putIfAbsent("@p4", "1111");
			
			//Create a map to map 
			m_labels = new HashMap<String, Integer>();
		}
		
		/** Parses a string holding an instruction and gets its 
		 * size in memory. Returns 0 if the instruction does not exist
		 * in this instruction set
		 * @param data_line
		 * @return
		 */
		public int getSizeInstruction(String data_line)
		{
			String args[] = data_line.split("\\s");
			for(int i = 0; i < args.length; i++)
			{
				if(args[i] == "")
				{
					continue;
				}
				
				for(Instruction in : m_instructions)
				{
					if(in.m_name.equals(args[i]))
					{
						return in.m_numWordsInMemory;
					}
				}	
			}
			return 0;
		}

		/**
		 * Adds a label to be used during assembly along with it's corresponding
		 * place in memory when used in branches or jumps
		 * @param label
		 * @param mem_counter
		 */
		public void addLabel(String label, int mem_counter)
		{
			m_labels.putIfAbsent(label, mem_counter);
		}

		/**
		 * Returns true if the string represents a label in the program
		 * @param data_line
		 * @return
		 */
		public boolean isLabel(String data_line)
		{
			String potentialLabel = data_line.replaceAll("\\s", "");
			if(potentialLabel.length()<2)
			{
				return false;
			}
			for(int i = 0; i < potentialLabel.length(); i++ )
			{
				if(i == potentialLabel.length() - 1)
				{
					return potentialLabel.charAt(i) == ':';
				}
				else
				{
					if(Character.isLetterOrDigit(potentialLabel.charAt(i)) || potentialLabel.charAt(i) == '_')
					{
						continue;
					}
					else
					{
						return false;
					}
				}
			}
			return false;
		}

		private HashSet<Instruction> m_instructions;
		private HashMap<String, String> m_registers;
		private HashMap<String, Integer> m_labels;
		
		/**
		 * This method takes an instruction and turns it into machine code
		 * @param in
		 * @return
		 */
		public String assembleInstruction(Instruction in)
		{
			String ret_val = null;
			if(isValidInstruction(in))
			{
				ret_val = in.m_opcode;
				if(in.m_numWordsInMemory == 1)
				{
					if(in.m_argTypes.get(0) == ArgType.REGISTER)
					{
						ret_val += m_registers.get(in.m_args.get(0));
						if(in.m_args.size() > 1)
						{
							//Two register args
							if(in.m_argTypes.get(1) == ArgType.REGISTER)
							{
								ret_val += m_registers.get(in.m_args.get(1));
							}
							//Shifts, reg imm args
							else
							{
								ret_val += getUnsignedBinaryImmediate(in.m_args.get(1), 4);
							}
						}
						else
						{
							//Incr case only has one arg, add padding
							ret_val += "0000";
						}
						ret_val += "000";
					}	
					
				}
				else if(in.m_numWordsInMemory == 2)
				{
					if(in.m_argTypes.get(0) == ArgType.IMMEDIATE)
					{
						ret_val += "0000" + getUnsignedBinaryImmediate(in.m_args.get(0), 23);
					}
					else
					{
						ret_val += m_registers.get(in.m_args.get(0));
						ret_val += getUnsignedBinaryImmediate(in.m_args.get(1), 23);
					}
				}
				else
				{
					return null;
				}
			}
			return ret_val;
		}
		
		/**
		 * This method takes a String that holds represents a positive unsigned
		 * immediate in decimal, hex, or octal and turns it into a binary string
		 * represented using the given number of bits
		 * @param immediate
		 * @param numBits
		 * @return
		 */
		private String getUnsignedBinaryImmediate(String immediate, int numBits)
		{
			String binaryInt;
			try
			{
				if(immediate.length() == 3 && immediate.charAt(0) == '\'' && immediate.charAt(2) == '\'')
				{
					immediate = "" + (0xFF00 | (int)immediate.charAt(1)); // This converts a character to its ascii code
				}
				binaryInt = Integer.toBinaryString(Integer.decode(immediate));
				if(binaryInt.length() > numBits)
				{
					binaryInt = binaryInt.substring(binaryInt.length() - numBits);
				}
				while(binaryInt.length() < numBits)
				{
					binaryInt = "0" + binaryInt;
				}
			}
			catch(Exception e)
			{
				e.printStackTrace();
				return null;
			}
			return binaryInt;
		}

		/**
		 * This method parses a string representing an instruction into an instruction object.
		 * Returns a null Instruction if the input is invalid.
		 * @param instruction
		 * @return
		 */
		public Instruction parseInstruction(String instruction)
		{
			if(instruction != null)
			{
				ArrayList<String> args = new ArrayList<String>(Arrays.asList(instruction.split("\\s")));
				
				//Remove all empty strings
				while(args.contains(""))
				{
					args.remove("");
				}
				
				//remove comma at end of args (not instruction name)
				for(int i = 1; i<args.size(); i++)
				{
					if((i < args.size() - 1) && args.get(i).equals("'") && args.get(i + 1).equals("'"))
					{
						String new_arg = args.get(i) + ' ' + args.get(i+1);
						args.set(i, new_arg);
						args.remove(i + 1);
					}
					String arg = args.get(i);
					if(arg.charAt(arg.length() - 1) == ',')
					{
						arg = arg.substring(0, arg.length() -1);
						args.set(i, arg);
					}
				}
				
				String name = null;
				if(args.size() != 0)
				{
					name = args.get(0);
					args.remove(0);
				}
				
				Instruction ret_val = new Instruction(name, null, -1, args, null);
				if(isValidInstruction(ret_val))
				{
					setOtherInstructionValues(ret_val);
					return ret_val;
				}
			}
			return null;
			
		}
		
		/**
		 * This is a helper method for parseInstruction. It just sets values of the instruction
		 * after it's been shown to be a valid instruction
		 * @param in
		 */
		private void setOtherInstructionValues(Instruction in)
		{
			Instruction template = null;
			for(Instruction instruction : m_instructions)
			{
				if(instruction.m_name.equals(in.m_name))
				{
					template = instruction;
				}
			}
			for(int i = 0; i<in.m_args.size(); i++)
			{
				//replace labels with their correct number
				if(m_labels.containsKey(in.m_args.get(i)))
				{
					in.m_args.set(i, Integer.toString(m_labels.get(in.m_args.get(i))));
				}
			}
			in.m_argTypes = new ArrayList<ArgType>(template.m_argTypes);
			in.m_numWordsInMemory = template.m_numWordsInMemory;
			in.m_opcode = template.m_opcode;
		}

		/**
		 * This method tests whether or not the instruction is contained
		 * in our instruction set.
		 * @param in
		 * @return
		 */
		private boolean isValidInstruction(Instruction in)
		{
			if(in == null)
			{
				return false;
			}
			Instruction template = null;
			for(Instruction instruction : m_instructions)
			{
				if(instruction.m_name.equals(in.m_name))
				{
					template = instruction;
				}
			}
			
			if(template == null)
			{
				return false;
			}
			
			boolean ret_val = true;
			ret_val = ret_val && (in.m_args.size() == template.m_argTypes.size());
			for(int i = 0; i<in.m_args.size(); i++)
			{
				//in and template aren't null. Must be same size or ret_val is false and the second part won't be executed here
				ret_val = ret_val && (parseArgType(in.m_args.get(i)) == template.m_argTypes.get(i));
			}
			
			//Instruction is in our inst. set, has valid arguments for the instruction. It's a valid instruction.
			return ret_val;
		}

		/**
		 * This takes a string representing an arg and returns its type. Returns UNKNOWN
		 * if invalid
		 * @param arg
		 * @return
		 */
		private ArgType parseArgType(String arg)
		{
			if(m_registers.containsKey(arg))
			{
				return ArgType.REGISTER;
			}
			try
			{
				//If it's a label, we're okay
				if(!m_labels.containsKey(arg))
				{
					//If it's an ascii char, we're okay
					if(arg.length() != 3 || arg.charAt(0) != '\'' || arg.charAt(2) != '\'')
					{	
						//Accepts decimal, hex, or octal. Otherwise throws NumberFormat Exception					
						Integer.decode(arg);
					}
				}
				return ArgType.IMMEDIATE;
			}
			catch(Exception e)
			{
				e.printStackTrace();
			}
			return ArgType.UNKNOWN;
		}

	}
		
		
}
	
		