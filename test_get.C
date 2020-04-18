#pragma runopts("XPLINK(ON)")
#include "utilities-1.h"
#include <cstdio>
#include <cerrno>
#include <cstdarg>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <fstream>
int main(int argc, char *argv[], char *envp[])
{
        std::cout << "Master Catalog:" << get_master_catalog_name();
        std::cout << "\tTemporary Directory:" << get_temp_dir_name();
        std::cout << std::endl;
        return 0;
}
