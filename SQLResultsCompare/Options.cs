using System;
using System.Text;
using CommandLine;
using CommandLine.Text;

namespace InfoCo.SQL.Test.SQLResultsCompare
{
    class Options
    {
        [Option('c', "category", Required = true, HelpText = "Query category (e.g. Policy).")]
        public string QueryCategory { get; set; }

        [Option('s', "subcategory", HelpText = "Query subcategory (e.g. Premium, GL).")]
        public string QuerySubcategory { get; set; }

        [Option('f', "filter", HelpText = "Query filter (e.g. PolicyNumber = 1234 AND Date BETWEEN '1900-01-01 AND '9999-12-31').")]
        public string QueryFilter { get; set; }

        [Option('b', "bcpargs", HelpText = "BCP arguments (see https://msdn.microsoft.com/en-us/library/ms162802.aspx).")]
        public string BCPArguments { get; set; }

        [Option('o', "outputdir", HelpText = "Query output directory.")]
        public string QueryOutputDir { get; set; }

        [Option('l', "compswitch", HelpText = "Compare tool switches.")]
        public string CompareSwitches { get; set; }

        [Option('d', DefaultValue = true, HelpText = "Delete existing output files.")]
        public bool DeleteExisting { get; set; }

        [HelpOption]
        public string GetUsage()
        {
            var help = new HelpText
            {
                Heading = new HeadingInfo("SQL Results Compare", "v0.1"),
                Copyright = new CopyrightInfo("Information Collaboration", 2016),
                AdditionalNewLineAfterOption = true,
                AddDashesToOption = true
            };
            help.AddPreOptionsLine("Usage: app -p Someone");
            help.AddOptions(this);
            return help;
        }
    }
}