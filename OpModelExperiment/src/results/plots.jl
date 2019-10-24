xticks = (1:2, ["Load Shedding", "Load Shedding"])
p = plot(xticks = xticks, ylabel = "Energy [MWh]", aspect_ratio = 1.77777, xlims=(0.8, 1.2))
boxplot!(load_shedding_uc./12, color = :gray, label = "UC")
boxplot!(load_shedding_suc./12, color = :white, label = "SUC")
Plots.savefig("first_measures.pdf")

xticks = (1:4, ["Fuel Cost", "Fuel Cost"])
p = plot(xticks = xticks, ylabel = "Fuel Cost [1000-\$]", aspect_ratio =3)
boxplot!(fuel_cost_uc./12e3, color = :gray, label = "UC")
boxplot!(fuel_cost_suc./12e3, color = :white, label = "SUC")
Plots.savefig("Fuel.pdf")


boxplot!(curtailment_uc./12, color = :gray, label = "UC")
boxplot!(curtailment_suc./12, color = :white, label = "SUC")
