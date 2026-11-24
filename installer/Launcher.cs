using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;
[assembly: System.Reflection.AssemblyTitle("LEMATZIUM")]
[assembly: System.Reflection.AssemblyProduct("LEMATZIUM")]
[assembly: System.Reflection.AssemblyVersion("1.3.3.0")]
[assembly: System.Reflection.AssemblyFileVersion("1.3.3.0")]
internal static class Launcher
{
    [STAThread]
    private static void Main()
    {
        try
        {
            string root = AppDomain.CurrentDomain.BaseDirectory;
            string runtime = Path.Combine(root, "runtime");
            string python = Path.Combine(runtime, "python.exe");
            string pythonw = Path.Combine(runtime, "pythonw.exe");
            string script = Path.Combine(root, "launcher", "lematzium_suite_launcher.py");
            if (!File.Exists(python) || !File.Exists(pythonw) || !File.Exists(script))
                throw new FileNotFoundException("No se encuentra el entorno integrado. Reinstala LEMATZIUM.");
            var p = new ProcessStartInfo(pythonw, "\"" + script + "\"");
            p.WorkingDirectory = root;
            p.UseShellExecute = false;
            p.CreateNoWindow = true;
            p.EnvironmentVariables["PYTHONHOME"] = runtime;
            p.EnvironmentVariables["PYTHONPATH"] = "";
            p.EnvironmentVariables["PYTHONNOUSERSITE"] = "1";
            p.EnvironmentVariables["PYTHONDONTWRITEBYTECODE"] = "1";
            p.EnvironmentVariables["LEMATZIUM_PYTHON"] = python;
            p.EnvironmentVariables["LEMATZIUM_INSTALLED"] = "1";
            Process.Start(p);
        }
        catch (Exception e)
        {
            MessageBox.Show(e.Message, "LEMATZIUM", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }
}
