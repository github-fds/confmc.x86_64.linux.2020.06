#if defined(TRX_AXI) || defined(BFM_AXI)
#	include "trx_axi_api.h"
#elif defined(TRX_AHB) || defined(BFM_AHB)
#	include "trx_ahb_api.h"
#else
#error TRX_AXI or TRX_AHB or BFM_AXI or BFM_AHB
#endif
