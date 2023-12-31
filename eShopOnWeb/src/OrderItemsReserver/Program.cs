﻿using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices((s) =>
    {
        s.AddHttpClient();
    })
    .Build();

host.Run();
