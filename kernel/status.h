typedef int32_t status_t;

inline bool succeeded(status_t status)
{
    return status >= 0;
}

inline bool failed(status_t status)
{
    return !succeeded(status)
}
