# IronPython in ANSYS WB: set geometry parameters, update, export forces
geom = GetTemplate(TemplateName='Geometry').GetSystem()
mesh = GetTemplate(TemplateName='Mesh').GetSystem()
fluent = GetTemplate(TemplateName='Fluid Flow (Fluent)').GetSystem()


P = geom.GetContainer(ComponentName='Geometry').Parameters
# Example: set control points CP1..CP12 from CSV
import csv
vals = list(csv.reader(open(r"C:\\temp\\dv.csv")))
for i,v in enumerate(vals[0], start=1):
P['CP%d' % i].Expression = v


UpdateAll()
# After solve, export L and D to CSV
fluent.Component1.Results["forceReport"].Export(r"C:\\temp\\forces.csv")
