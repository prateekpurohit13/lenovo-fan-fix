# Out-of-tree modules for Lenovo Yoga Pro 7 14IAH10 (83KF) fan support:
#   yogafan            - fan RPM monitoring (patched ACPI paths)
#   lenovo-wmi-*       - WMI "Other Mode" fan RPM control (patched bind logic)
#
# Build with ./build.sh  (wraps: make -C /lib/modules/<ver>/build M=$PWD modules)

obj-m += yogafan.o
obj-m += lenovo-wmi-helpers.o
obj-m += lenovo-wmi-capdata.o
obj-m += lenovo-wmi-other.o

lenovo-wmi-helpers-y := wmi-helpers.o
lenovo-wmi-capdata-y  := wmi-capdata.o
lenovo-wmi-other-y    := wmi-other.o
