# Simply declares windows:nssm to download and install nssm
#   This requires the counsyl/windows puppet module
#
# Note you do not have to declare the nssm class if you 
# already have nssm installed
class nssm {
  # include windows::nssm
}
