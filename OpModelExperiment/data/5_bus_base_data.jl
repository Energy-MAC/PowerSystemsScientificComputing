nodes5    = [Bus(1,"nodeA", "PV", 0, 1.0, (min = 0.9, max=1.05), 230),
             Bus(2,"nodeB", "PQ", 0, 1.0, (min = 0.9, max=1.05), 230),
             Bus(3,"nodeC", "PV", 0, 1.0, (min = 0.9, max=1.05), 230),
             Bus(4,"nodeD", "REF", 0, 1.0, (min = 0.9, max=1.05), 230),
             Bus(5,"nodeE", "PV", 0, 1.0, (min = 0.9, max=1.05), 230),
            ];

branches5 = [Line("1", true, 0.0, 0.0, Arc(from=nodes5[1],to=nodes5[2]), 0.00281, 0.0281, (from=0.00356, to=0.00356), 2.0, (min = -0.7, max = 0.7)),
             Line("2", true, 0.0, 0.0, Arc(from=nodes5[1],to=nodes5[4]), 0.00304, 0.0304, (from=0.00329, to=0.00329), 2.0, (min = -0.7, max = 0.7)),
             Line("3", true, 0.0, 0.0, Arc(from=nodes5[1],to=nodes5[5]), 0.00064, 0.0064, (from=0.01563, to=0.01563), 18.8120, (min = -0.7, max = 0.7)),
             Line("4", true, 0.0, 0.0, Arc(from=nodes5[2],to=nodes5[3]), 0.00108, 0.0108, (from=0.00926, to=0.00926), 11.1480, (min = -0.7, max = 0.7)),
             Line("5", true, 0.0, 0.0, Arc(from=nodes5[3],to=nodes5[4]), 0.00297, 0.0297, (from=0.00337, to=0.00337), 40.530, (min = -0.7, max = 0.7)),
             Line("6", true, 0.0, 0.0, Arc(from=nodes5[4],to=nodes5[5]), 0.00297, 0.0297, (from=0.00337, to=00.00337), 2.00, (min = -0.7, max = 0.7))
]

thermal_generators5_uc_testing = [ThermalStandard("Alta", true, nodes5[1], 0.0, 0.0,
           TechThermal(0.5, PowerSystems.CT, PowerSystems.NATURAL_GAS, (min=0.52, max=1.40),  (min = -0.30, max = 0.30), (up=0.5, down=0.5), (up=1.0, down=1.0)),
           ThreePartCost([ (7122.4347750000002, 0.52),
                                 (7317.43201358, 0.73),
                                 (7642.4891244200003, 0.94),
                                 (8775.88432216, 1.4)], 7122.4347750000002, 5665.23, 0.)
           ),
           ThermalStandard("Park City", true, nodes5[1], 0.0, 0.0,
               TechThermal(2.2125, PowerSystems.CT, PowerSystems.NATURAL_GAS, (min=0.52, max=1.70), (min =-1.275, max=1.275), (up=0.5, down=0.5), (up=1.0, down=1.0)),
               ThreePartCost([(7141.9330705200002, 0.52)
                             (7348.7746684400001, 0.83)
                             (7670.1972285800002, 1.04)
                             (9260.4196955, 1.7)], 7141.9, 5665.23, 0.0)
           ),
           ThermalStandard("Solitude", true, nodes5[3], 0.0, 0.00,
               TechThermal(5.20, PowerSystems.CC, PowerSystems.NATURAL_GAS, (min=2.7, max=5.20), (min =-3.90, max=3.90), (up=0.015, down=0.015), (up=5.0, down=3.0)),
               ThreePartCost([(4877.567034952806, 2.7),
                             (5507.368250673228, 3.32),
                             (8374.484237754725, 4.93),
                             (9331.01276343956, 5.20)], 4877.56, 28046.0, 0.0)
           ),
           ThermalStandard("Sundance", true, nodes5[4], 0.0, 0.00,
               TechThermal(2.5, PowerSystems.ST, PowerSystems.COAL, (min=0.92, max=2.0), (min =-1.5, max=1.5), (up=0.025, down=0.025), (up=2.0, down=1.0)),
               ThreePartCost([(5437.4159564599997, 0.92),
                             (6039.7361012499996, 1.43),
                             (6751.7596430999997, 1.74),
                             (7775.854616729999, 2.0) ], 5437.4, 11172.0, 0.0)
           ),
           ThermalStandard("Brighton", true, nodes5[5], 3.7, 0.0,
               TechThermal(7.5, PowerSystems.CC, PowerSystems.NATURAL_GAS, (min=3.7, max=6.0), (min =-4.50, max=4.50), (up=0.015, down=0.015), (up=5.0, down=3.0)),
               ThreePartCost([(4551.118299650451, 3.7),
                                 (5577.404111319302, 4.32),
                                 (7600.733096364351, 5.24),
                                 (9828.37578065609, 6.00)  ], 4551.11, 28046.0, 0.0)
           )];


loads5 = [ PowerLoad("Bus2", true, nodes5[2], PowerSystems.ConstantPower, 2.1, 0.9861, 4.6, 0.9861),
           PowerLoad("Bus3", true, nodes5[3], PowerSystems.ConstantPower, 2.1, 0.9861, 4.6, 0.9861),
           PowerLoad("Bus4", true, nodes5[4], PowerSystems.ConstantPower, 2.1, 1.3147, 2.1, 1.3147),
        ];

il = InterruptibleLoad("IloadBus4", true, nodes5[4], PowerSystems.ConstantPower, 2.10, 1.8,  3.10, 2.0,
                        TwoPartCost((0.0, 2400.0), 38046.0))



renewable_generators5 = [RenewableDispatch("WindBusA", true, nodes5[5], 0.0, 0.0, PowerSystems.WT, 1.200, TwoPartCost(22.0, 0.0)),
                         RenewableDispatch("WindBusB", true, nodes5[4], 0.0, 0.0, PowerSystems.WT, 1.200, TwoPartCost(22.0, 0.0)),
                         RenewableDispatch("WindBusC", true, nodes5[3], 0.0, 0.0, TechRenewable(1.20, PowerSystems.WT, (min = -0.800, max = 0.800), 1.0), TwoPartCost(22.0, 0.0))];



reserve5 = StaticReserve("Spinning", thermal_generators5_uc_testing, 1.0, 1.0)
