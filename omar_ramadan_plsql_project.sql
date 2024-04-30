CREATE OR REPLACE FUNCTION calc_installment_amount (
    CONTRACT_TOTAL_FEES NUMBER,
    CONTRACT_DEPOSIT_FEES NUMBER,
    CONTRACT_PAYMENT_TYPE VARCHAR2 , 
        CONTRACT_STARTDATE DATE,
    CONTRACT_ENDDATE DATE

) RETURN NUMBER
IS
    v_installment_amount NUMBER;
    v_contract_years NUMBER ;
BEGIN
 v_contract_years := Months_between(CONTRACT_ENDDATE ,  CONTRACT_STARTDATE)  / 12 ;
    IF(CONTRACT_DEPOSIT_FEES IS NOT NULL) THEN
        IF CONTRACT_PAYMENT_TYPE = 'ANNUAL' THEN
            v_installment_amount := (CONTRACT_TOTAL_FEES - CONTRACT_DEPOSIT_FEES) / ( 1 *  v_contract_years );
        ELSIF CONTRACT_PAYMENT_TYPE = 'QUARTER' THEN
            v_installment_amount := (CONTRACT_TOTAL_FEES - CONTRACT_DEPOSIT_FEES) /  ( 4 *  v_contract_years );
        ELSIF CONTRACT_PAYMENT_TYPE = 'MONTHLY' THEN
            v_installment_amount := (CONTRACT_TOTAL_FEES - CONTRACT_DEPOSIT_FEES) /( 12 *  v_contract_years );
        ELSIF CONTRACT_PAYMENT_TYPE = 'HALF_ANNUAL' THEN
            v_installment_amount := (CONTRACT_TOTAL_FEES - CONTRACT_DEPOSIT_FEES) /( 2 *  v_contract_years );
        END IF;
    ELSE
        IF CONTRACT_PAYMENT_TYPE = 'ANNUAL' THEN
            v_installment_amount := CONTRACT_TOTAL_FEES / ( 1 *  v_contract_years );
        ELSIF CONTRACT_PAYMENT_TYPE = 'QUARTER' THEN
            v_installment_amount := CONTRACT_TOTAL_FEES /  ( 4 *  v_contract_years );
        ELSIF CONTRACT_PAYMENT_TYPE = 'MONTHLY' THEN
            v_installment_amount := CONTRACT_TOTAL_FEES / ( 12 *  v_contract_years );
        ELSIF CONTRACT_PAYMENT_TYPE = 'HALF_ANNUAL' THEN
            v_installment_amount := CONTRACT_TOTAL_FEES /( 2 *  v_contract_years );
        END IF;
    END IF;

    RETURN v_installment_amount;
END calc_installment_amount;
/


CREATE OR REPLACE FUNCTION calc_period (
    CONTRACT_PAYMENT_TYPE VARCHAR2
) RETURN INTERVAL YEAR TO MONTH
IS
    v_period INTERVAL YEAR TO MONTH;
BEGIN
    IF CONTRACT_PAYMENT_TYPE = 'ANNUAL' THEN
        v_period := INTERVAL '1' YEAR;
    ELSIF CONTRACT_PAYMENT_TYPE = 'QUARTER' THEN
        v_period := INTERVAL '3' MONTH;
    ELSIF CONTRACT_PAYMENT_TYPE = 'MONTHLY' THEN
        v_period := INTERVAL '1' MONTH;
    ELSIF CONTRACT_PAYMENT_TYPE = 'HALF_ANNUAL' THEN
        v_period := INTERVAL '6' MONTH;
    END IF;

    RETURN v_period;
END calc_period;
/

DECLARE
    CURSOR contracts_cursor IS
        SELECT * FROM CONTRACTS;

    v_installment_date DATE;
    v_period INTERVAL YEAR TO MONTH;
    v_last_installment_date DATE;
    v_installment_amount NUMBER;
 
BEGIN
    FOR v_contract_record IN contracts_cursor LOOP
        v_installment_date := v_contract_record.CONTRACT_STARTDATE;
        v_period := calc_period(v_contract_record.CONTRACT_PAYMENT_TYPE);
        v_installment_amount := calc_installment_amount(
            v_contract_record.CONTRACT_TOTAL_FEES,
            v_contract_record.CONTRACT_DEPOSIT_FEES,
            v_contract_record.CONTRACT_PAYMENT_TYPE,
            v_contract_record.CONTRACT_STARTDATE,
            v_contract_record.CONTRACT_ENDDATE
        );

          INSERT INTO INSTALLMENTS_PAID (
                INSTALLMENT_ID,  CONTRACT_ID,   INSTALLMENT_DATE,    INSTALLMENT_AMOUNT,   PAID )
          
            VALUES (
                INSTALLMENTS_PAID_SEQ.nextval,   v_contract_record.CONTRACT_ID,   TO_DATE(TO_CHAR(v_installment_date, 'DD/MM/YYYY') , 'DD/MM/YYYY'),   v_installment_amount,   0  );

        v_last_installment_date := v_installment_date + v_period;

        WHILE v_last_installment_date < v_contract_record.CONTRACT_ENDDATE LOOP
            v_installment_date := v_installment_date + v_period;
            v_last_installment_date := v_installment_date + v_period;

            INSERT INTO INSTALLMENTS_PAID (
                INSTALLMENT_ID,  CONTRACT_ID,   INSTALLMENT_DATE,    INSTALLMENT_AMOUNT,   PAID )
          
            VALUES (
                INSTALLMENTS_PAID_SEQ.nextval,   v_contract_record.CONTRACT_ID,   TO_DATE(TO_CHAR(v_installment_date, 'DD/MM/YYYY') , 'DD/MM/YYYY'),   v_installment_amount,   0  );
              
        END LOOP;
    END LOOP;
END;
/



SELECT * FROM HR.INSTALLMENTS_PAID;
