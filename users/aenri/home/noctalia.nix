{ inputs, ... }:
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia-shell = {
    settings = {
      bar = {
        widgets = {
          center = [
            {
              id = "Workspace";
            }
          ];
          left = [
            {
              id = "Launcher";
              enableColorization = true;
              colorizeSystemIcon = "error";
              icon = "hearts";
              useDistroLogo = false;
            }
            {
              id = "Clock";
              clockColor = "primary";
              formatHorizontal = "yyyy/MM/dd @ HH:mm:ss";
              tooltipFormat = "HH:mm ddd, MMM dd";
            }
            {
              id = "SystemMonitor";
              diskPath = "/";
              iconColor = "primary";
              showCpuCores = false;
              showCpuFreq = false;
              showCpuTemp = false;
              showCpuUsage = true;
              showDiskAvailable = false;
              showDiskUsage = false;
              showDiskUsageAsPercent = false;
              showGpuTemp = false;
              showLoadAverage = false;
              showMemoryAsPercent = true;
              showMemoryUsage = true;
              showNetworkStats = false;
              showSwapUsage = false;
            }
            {
              id = "MediaMini";
              maxWidth = 500;
              
            }
          ];
        };
      };
    };
  };
}