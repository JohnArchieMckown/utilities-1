#include <string.h>
char *get_master_catalog_name(void)
{
        static char m_cat[45];
        char *cvt;
        char *cvtecvt;
        char *cvtipa;
        char *blank;
        cvt = *((char **)0x10);
        cvtecvt = *((char **)(cvt + 140));
        cvtipa = *((char **)(cvtecvt + 392));
        memcpy(m_cat, cvtipa + 234, 44);
        if (NULL == (blank = memchr(m_cat, ' ', sizeof m_cat)))
                m_cat[44] = '\0';
        else
                *blank = '\0';
        return m_cat;
}
