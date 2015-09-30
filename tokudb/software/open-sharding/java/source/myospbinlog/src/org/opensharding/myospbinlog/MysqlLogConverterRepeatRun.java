package org.opensharding.myospbinlog;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.Charset;
import java.util.Properties;

/**
 * MysqlLogConverter
 * 
 * Copyright (c) 2011 CodeFutures Corporation. All rights reserved.
 * 
 * @author CodeFutures
 *
 */
public class MysqlLogConverterRepeatRun {
	
	
	private BufferedReader reader;
	private BufferedWriter writer;
	private Charset charSet;

	private final String NEWLINE = "\n";
	private final String ENDOFSTATEMENT = "/*!*/;";
	private final String INSERTID = "INSERT_ID";
	private final String TIMESTAMP = "TIMESTAMP";
	private final String[] KEYWORDS = { "BEGIN", "COMMIT", "INSERT", "UPDATE",
			"DELETE", "CREATE", "DROP", "ALTER", INSERTID, TIMESTAMP};

	private String sql = "";
	private String currentWord = "";
	private boolean isStatement = false;
	
	int i = 0;

	/**
	 * 
	 * @param args
	 */
	public static void main(String[] args) {
		MysqlLogConverterRepeatRun converter = new MysqlLogConverterRepeatRun();
		converter.convert(args);
	}

	/**
	 * 
	 */
	public void convert(String[] args) {
		try {
			init(args);
			while (readLine()) {
			}

			writer.flush();
			writer.close();
			
			System.exit(0);
		} catch (Exception e) {
			e.printStackTrace();
		}

	}

	/**
	 * 
	 * @return
	 * @throws Exception
	 */
	public boolean readLine() throws Exception {
		if (reader == null) {
			throw new IOException(
					"The reader must be initialzed. Ensure that the proper constructor has been selected which provides a File or InputStream.");
		}
		if (writer == null) {
			throw new IOException("The writer must be initialzed.");
		}

		char ch;
		int _ch;

		while (true) {
			_ch = reader.read();
			if (_ch == -1) {
				// EOF found
				return false;
			}
			ch = (char) _ch;
			
			currentWord += ch;
			if (currentWord.contains(" ") || currentWord.contains("\n")){
				if (currentWord.contains("\n")){
					currentWord = currentWord.substring(0, currentWord.length() -1);
				}
				String tempCurrentWord = currentWord;
				currentWord = "";
				
				if (!isStatement) {
					for (String keyWord : KEYWORDS) {
						if (tempCurrentWord.contains(keyWord)) {
							if (tempCurrentWord.contains(INSERTID)){
								sql = tempCurrentWord.replace(INSERTID, "/* OSP_AUTO_INCREMENT");
								sql = sql.replace(ENDOFSTATEMENT, " */\n");
								writer.write(sql);
								tempCurrentWord = "";
								sql = "";
							} else if (tempCurrentWord.contains(TIMESTAMP) && (!tempCurrentWord.contains("OSP_TIMESTAMP") )){
								sql = tempCurrentWord.replace(TIMESTAMP, "/* OSP_TIMESTAMP");
								sql = sql.replace(ENDOFSTATEMENT, " */\n");
								writer.write(sql);
								tempCurrentWord = "";
								sql = "";								
							} else {
								isStatement = true;
							}
						}
					}
				}
				
				if (isStatement) {
					if (tempCurrentWord.contains(ENDOFSTATEMENT)){
						tempCurrentWord = tempCurrentWord.replace(ENDOFSTATEMENT, "");
						sql += tempCurrentWord;
						sql += "\n;\n";
						writer.write(sql);
						sql = "";
						isStatement = false;
					} else {
						sql += tempCurrentWord;
					}
					tempCurrentWord = "";
				}
				
				if(NEWLINE.equals(Character.toString(ch))){
					return true;
				}
			}
		}
	}

	/**
	 * 
	 * @throws Exception
	 */
	public void init(String[] args) throws Exception {
		String charSetName;
		String inputLogDir;
		String inputLogName;
		File inputLog;
		File outputSql;
		
		//get properties
		charSetName = args[0];
		inputLogDir = args[1];
		inputLogName = args[2];
		inputLog = new File(inputLogDir + "/text/" + inputLogName + ".txt");
		outputSql = new File(inputLogDir + "/sql_temp/" + inputLogName);
		
		// initiation
		this.charSet = Charset.forName(charSetName);
		this.reader = new BufferedReader(new InputStreamReader(
				new FileInputStream(inputLog), charSet));
		this.writer = new BufferedWriter(new FileWriter(outputSql));
	}
}
