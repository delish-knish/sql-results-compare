using System;
using System.IO;
using System.Text;
using System.Data;
using System.Configuration;
using System.Data.SqlClient;
using System.Diagnostics;
using CommandLine;
using Microsoft.SqlServer.Management.Smo;
using Microsoft.SqlServer.Management.Common;
using Microsoft.SqlServer.Dac;
using System.Collections.Generic;

namespace InfoCo.Sql.Test.SqlResultsCompare
{
    class Program
    {
        private static object ArgQueryCategory { get; set; }
        private static object ArgQuerySubcategory { get; set; }
        private static object ArgQueryFilter { get; set; }
        private static string ArgBCPArguments { get; set; }
        private static string ArgCompareExePath { get; set; }
        private static string ArgCompareSwitches { get; set; }
        private static string ArgQueryOutputDir { get; set; }
        private static bool ArgDeleteExisting { get; set; }
        private static bool ArgCreateDatabase { get; set; }
        private static List<string> MessageList { get; set; }

        static void Main(string[] args)
        {
            try
            {                
                var options = new Options();
                if (CommandLine.Parser.Default.ParseArguments(args, options))
                {
                    //Determine final argument values for process
                    ArgQueryCategory = (options.QueryCategory != null) ? (object)options.QueryCategory : DBNull.Value;
                    ArgQuerySubcategory = (options.QuerySubcategory != null) ? (object)options.QuerySubcategory : DBNull.Value;
                    ArgQueryFilter = (options.QueryFilter != null) ? (object)options.QueryFilter : DBNull.Value;
                    ArgBCPArguments = (options.BCPArguments != null ? options.BCPArguments : ConfigurationManager.AppSettings["DefaultBCPArguments"]);
                    ArgCompareExePath = ConfigurationManager.AppSettings["CompareExePath"];
                    ArgCompareSwitches = (options.CompareSwitches != null ? options.CompareSwitches : ConfigurationManager.AppSettings["DefaultCompareSwitches"]);
                    ArgQueryOutputDir = (options.QueryOutputDir != null ? options.QueryOutputDir : ConfigurationManager.AppSettings["DefaultQueryOutputDir"]);
                    ArgDeleteExisting = options.DeleteExisting;
                    ArgCreateDatabase = options.CreateDatabase;

                    //Set up connection string
                    string dbConnString = ConfigurationManager.ConnectionStrings["DBConnectionString"].ToString();

                    //Get the servername
                    SqlConnectionStringBuilder connStringBuilder = new SqlConnectionStringBuilder(dbConnString);
                    string serverName = connStringBuilder.DataSource;

                    if (ArgCreateDatabase == true)
                    {
                        bool deploySuccess = DeployDatabase(serverName, dbConnString);
                        string deployMessage;
                        deployMessage = (deploySuccess == true ? "SqlResultsCompare database deployed successfully on " + serverName + "." : "SqlResultsCompare database deployment failed on " + serverName + ".");
                        Console.WriteLine("SqlResultsCompare database deployed successfully to " + serverName + ".");
                        return;
                    }

                    //Display all values being used to run the process
                    Console.ForegroundColor = ConsoleColor.Cyan;
                    Console.WriteLine("Query Category: " + ArgQueryCategory.ToString());
                    Console.WriteLine("Query Subcategory: " + ArgQuerySubcategory.ToString());
                    Console.WriteLine("Query Filter: " + ArgQueryFilter);
                    Console.WriteLine("BCP Arguments: " + ArgBCPArguments);
                    Console.WriteLine("SQL Server: " + serverName);
                    Console.WriteLine("Compare Exe Path: " + ArgCompareExePath);
                    Console.WriteLine("Compare Switches: " + ArgCompareSwitches);
                    Console.WriteLine("Output Dir: " + ArgQueryOutputDir);
                    Console.WriteLine("Delete Existing: " + ArgDeleteExisting);
                    Console.WriteLine("\r\n");
                    Console.ResetColor();

                    //Start the process
                    Console.ForegroundColor = ConsoleColor.Green;
                    Console.WriteLine("Process started ...\r\n");
                    Console.ResetColor();

                    //Create directory if it doesn't exist
                    System.IO.Directory.CreateDirectory(ArgQueryOutputDir);

                    //If enabled, delete exsiting query output files
                    if (ArgDeleteExisting)
                    {
                        Console.WriteLine("\tDirectory cleanup started...");
                        Console.WriteLine("\t\t" + DeleteFiles(ArgQueryOutputDir) + " file(s) deleted.");
                        Console.WriteLine("\tDirectory cleanup complete.\r\n");
                    }                 

                    //Generate output files to compare
                    Console.WriteLine("\tFile generation started...");
                    Console.WriteLine("\t\t" + GenerateFilePairs(dbConnString, ArgQueryCategory, ArgQuerySubcategory, ArgQueryFilter, ArgBCPArguments, serverName, ArgQueryOutputDir) + " set(s) of comparison files created.");
                    Console.WriteLine("\tFile generation complete.\r\n");

                    //Compare output files
                    Console.WriteLine("\tCompares started...");
                    CompareFilePairs(dbConnString, ArgCompareExePath, ArgCompareSwitches);
                    Console.WriteLine("\tCompares complete.\r\n");

                    Console.ForegroundColor = ConsoleColor.Green;
                    Console.WriteLine("Process completed successfully.");
                    Console.ResetColor();
                }
                else
                {
                    if (args.Length > 0)
                    {
                        if (args[0] != "--help")
                        { 
                            Console.WriteLine(options.GetUsage());
                        }
                    }
                }
            }
            catch(Exception ex)
            {
                //ToDo: implement log4net logging
                Console.WriteLine("Exception encountered: " + ex.Message);
            }
        }

        private static int GenerateFilePairs(string databaseConnectionString, object categoryName, object subcategoryName, object filter, string bcpArguments, string bcpServerName, string queryOutputDir)
        {
            SqlConnection DBConn = new SqlConnection(databaseConnectionString);
            SqlCommand GenerateComparisonFiles = new SqlCommand("SqlResultsCompare.dbo.CreateQueryOutput", DBConn);
            GenerateComparisonFiles.CommandTimeout = Convert.ToInt32(ConfigurationManager.AppSettings["QueryTimeout"]);
            GenerateComparisonFiles.CommandType = CommandType.StoredProcedure;

            SqlParameter QueryCategory = GenerateComparisonFiles.Parameters.Add("@QueryComparisonCategoryName", SqlDbType.VarChar, 50);
            QueryCategory.Value = categoryName;

            SqlParameter QuerySubcategory = GenerateComparisonFiles.Parameters.Add("@QueryComparisonSubcategoryName", SqlDbType.VarChar, 50);
            QuerySubcategory.Value = subcategoryName;

            SqlParameter QueryFilter = GenerateComparisonFiles.Parameters.Add("@QueryFilter", SqlDbType.VarChar, -1);
            QueryFilter.Value = filter;

            SqlParameter BCPArguments = GenerateComparisonFiles.Parameters.Add("@BCPArguments", SqlDbType.VarChar, 1000);
            BCPArguments.Value = bcpArguments;

            SqlParameter BCPServerName = GenerateComparisonFiles.Parameters.Add("@BCPServerName", SqlDbType.VarChar, 250);
            BCPServerName.Value = bcpServerName;

            SqlParameter QueryOutputDir = GenerateComparisonFiles.Parameters.Add("@QueryOutputDir", SqlDbType.VarChar, -1);
            QueryOutputDir.Value = queryOutputDir;

            SqlParameter ComparisonCount = GenerateComparisonFiles.Parameters.Add("@ComparisonCount", SqlDbType.VarChar, -1);
            ComparisonCount.Direction = ParameterDirection.Output;
            
            DBConn.Open();
            GenerateComparisonFiles.ExecuteNonQuery();

            var FilePairCount = Convert.ToInt16(GenerateComparisonFiles.Parameters["@ComparisonCount"].Value);

            return FilePairCount;
        }

        private static void CompareFilePairs(string databaseConnectionString, string compareExePath, string compareSwitches)
        {
            SqlConnection DBConn = new SqlConnection(databaseConnectionString);
            SqlCommand GetFilePairs = new SqlCommand("SqlResultsCompare.dbo.GetFilePairs", DBConn);
            GetFilePairs.CommandType = CommandType.StoredProcedure;
            DBConn.Open();
            SqlDataReader FilePairs = GetFilePairs.ExecuteReader();

            if(FilePairs.HasRows)
            {
                var comparisonCounter = 1;
                while (FilePairs.Read())
                {
                    var baselineFilePath = FilePairs.GetValue(0);
                    var comparisonFilePath = FilePairs.GetValue(1);
                    var comparisonDescription = FilePairs.GetValue(2);                    
                   
                    Process.Start(compareExePath, compareSwitches + " " + baselineFilePath + " " + comparisonFilePath);
                    Console.WriteLine("\t\tComparision #" + comparisonCounter.ToString() + ": \"" + comparisonDescription + "\" complete.");
                    comparisonCounter += 1;
                }
            }
            else
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("**No files to compare!");
                Console.ResetColor();
            }
        }
        private static int DeleteFiles(string filePath)
        {
            //Array.ForEach(Directory.GetFiles(filePath), File.Delete);
            var fileCount = 0;

            System.IO.DirectoryInfo di = new DirectoryInfo(filePath);
            foreach (FileInfo file in di.GetFiles())
            {
                file.Delete();
                fileCount += 1;
            }
            return fileCount;
        }

        private static bool DeployDatabase(string databaseServerName, string connString)
        {
            MessageList = new List<string>();
            bool success = true;
            var dacSvc = new DacServices(connString);
            var dacOptions = new DacDeployOptions();
            dacOptions.BlockOnPossibleDataLoss = false;

            try
            {
                using (DacPackage dacpac = DacPackage.Load(@"Database Deployment\SqlResultsCompare.dacpac"))
                {
                    dacSvc.Deploy(dacpac, "SqlResultsCompare", upgradeExisting: true, options: dacOptions);
                }

            }
            catch (Exception ex)
            {
                success = false;
                MessageList.Add(ex.Message);
            }
            return success;
        }
    }
}
