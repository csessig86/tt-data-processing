SELECT dataPEPANNRES."GEO.id2", dataPEPANNRES."GEO.display-label", dataPEPANNRES."respop72010", dataPEPANNRES."respop72011", dataPEPANNRES."respop72012", dataPEPANNRES."respop72013", dataPEPANNRES."respop72014", dataPEPANNRES."respop72015", dataPEPANNRES."respop72016", CAST(printf("%.2f", (( CAST(dataPEPANNRES."respop72016" as float) - CAST(dataPEPANNRES."respop72010" as float) ) / dataPEPANNRES."respop72010") * 100) as float) as percent
FROM dataPEPANNRES
WHERE dataPEPANNRES."respop72016" > 10000
ORDER BY percent DESC
LIMIT 10;