#include<iostream>
using namespace std;
void print(char *);
void print(const char *ch)
{
        cout << ch << endl;
}

int main()
{
        print("Hello");
        return 0;
}
